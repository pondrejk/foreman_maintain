module Reports
  class Inventory < ForemanMaintain::Report
    metadata do
      description 'Facts about hosts and the rest of the inventory'
    end

    def run
      merge_data('hosts_by_type_count') { hosts_by_type_count }
      merge_data('hosts_by_os_count') { hosts_by_os_count }
      merge_data('hosts_by_family_count') { hosts_by_family_count }
      merge_data('facts_by_type') { facts_by_type }
      merge_data('audits') { audits }
      merge_data('parameters_count') { parameters }
      hosts_running_rhel_ai
    end

    # Hosts
    def hosts_by_type_count
      query("select type, count(*) from hosts group by type").
        to_h { |row| [(row['type'] || '').sub('Host::', ''), row['count'].to_i] }
    end

    # OS usage
    def hosts_by_os_count
      query(
        <<-SQL
            select max(operatingsystems.name) as os_name, count(*) as hosts_count
            from hosts inner join operatingsystems on operatingsystem_id = operatingsystems.id
            group by operatingsystems.name
        SQL
      ).
        to_h { |row| [row['os_name'], row['hosts_count'].to_i] }
    end

    def hosts_by_family_count
      query(
        <<-SQL
            select max(operatingsystems.type) as os_family, count(*) as hosts_count
            from hosts inner join operatingsystems on operatingsystem_id = operatingsystems.id
            group by operatingsystems.type
        SQL
      ).
        to_h { |row| [row['os_family'], row['hosts_count'].to_i] }
    end

    # Facts usage
    def facts_by_type
      query(
        <<-SQL
            select fact_names.type,
                    min(fact_values.updated_at) as min_update_time,
                    max(fact_values.updated_at) as max_update_time,
                    count(fact_values.id) as values_count
            from fact_values inner join fact_names on fact_name_id = fact_names.id
            group by fact_names.type
        SQL
      ).
        to_h { |row| [row['type'].sub('FactName', ''), to_fact_hash(row)] }
    end

    # Audits
    def audits
      audits_query =
        query(
          <<-SQL
            select count(*) as records_count,
                    min(created_at) as min_created_at,
                    max(created_at) as max_created_at
            from audits
          SQL
        )
      to_audits_record(audits_query.first)
    end

    # Parameters
    def parameters
      query("select type, count(*) from parameters group by type").
        to_h { |row| [row['type'], row['count'].to_i] }
    end

    def to_fact_hash(row)
      {
        min_update_time: row['min_update_time'],
        max_update_time: row['max_update_time'],
        values_count: row['values_count'].to_i,
      }
    end

    def to_audits_record(row)
      {
        records_count: row['records_count'].to_i,
        min_created_at: row['min_created_at'],
        max_created_at: row['max_created_at'],
      }
    end

    def hosts_running_rhel_ai
      query = <<~SQL
        hosts
        INNER JOIN katello_subscription_facets AS ksf ON hosts.id = ksf.host_id
        INNER JOIN katello_subscription_facet_installed_products AS ksfip ON ksfip.subscription_facet_id = ksf.id
        INNER JOIN katello_installed_products AS kip ON ksfip.installed_product_id = kip.id
        WHERE kip.name = 'Red Hat Enterprise Linux AI'
      SQL
      data_field('rhel_ai_workload_host_count') { sql_count(query) }
    end
  end
end
