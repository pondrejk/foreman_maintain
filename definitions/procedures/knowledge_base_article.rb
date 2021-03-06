class Procedures::KnowledgeBaseArticle < ForemanMaintain::Procedure
  metadata do
    description 'Show knowledge base article for troubleshooting'

    confine do
      feature(:downstream)
    end
    param :doc,
          'Document name required to select a correct article',
          :required => true
    advanced_run false
  end

  def run
    ask(<<-MESSAGE.strip_heredoc)
      Go to #{kcs_documents[@doc]}
      please follow steps from above article to resolve this issue
      press ENTER once done.
    MESSAGE
  end

  private

  def kcs_documents
    {
      'fix_cpdb_validate_failure' => 'https://access.redhat.com/solutions/3362821',
      'upgrade_puppet_guide_for_sat63' => 'https://access.redhat.com/documentation/en-us/red_hat_satellite/6.3/html/upgrading_and_updating_red_hat_satellite/upgrading_puppet-1'
    }
  end
end
