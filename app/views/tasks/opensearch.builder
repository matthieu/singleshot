xml.tag! 'OpenSearchDescription', 'xmlns'=>'http://a9.com/-/spec/opensearch/1.1/' do
  xml.tag! 'ShortName', 'Singleshot'
  xml.tag! 'Description', 'Search your tasks list'
  xml.tag! 'Url', 'type'=>'text/html', 'template'=>search_url('q'=>'{searchTerms}')
end
