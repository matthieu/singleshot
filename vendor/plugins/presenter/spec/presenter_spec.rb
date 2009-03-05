require File.join(File.dirname(__FILE__), 'helper')


describe 'Presenter', :type=>:controller do
  controller_name :foo

  it 'should derive item name from class name' do
    FooPresenter.item_name.should == 'foo'
  end
  
  it 'should derive array name from element name' do
    FooPresenter.array_name.should == 'foos'
  end
  
  it 'should have accessor for controller' do
    presenting(Foo.new).controller.should == controller
  end

  describe '(instance)' do
    before { @presenter = presenting(@item = Foo.new) }

    it 'should provide object from #item accessor' do
      @presenter.item.should == @item
    end
    
    it 'should provide object from (item) accessor' do
      @presenter.foo.should == @item
    end
    
    it 'should provide nothing from #array accessor' do
      @presenter.array.should be_nil
    end
    
    it 'should use hash_for(instance) for to_json' do
      @presenter.should_receive(:hash_for).with(@item).and_return('bar'=>'beer')
      @presenter.to_json.should == %{{"bar": "beer"}}
    end

    it 'should use hash_for(instance) for to_xml with model name' do
      @presenter.should_receive(:hash_for).with(@item).and_return('bar'=>'beer')
      @presenter.to_xml(:indent=>0).should == %{<?xml version=\"1.0\" encoding=\"UTF-8\"?><foo><bar>beer</bar></foo>}
    end
    
  end

  describe '(array)' do
    before { @presenter = presenting(@array = [Foo.new, Foo.new]) }
    
    it 'should provide array from #array accessor' do
      @presenter.array.should == @array
    end
    
    it 'should provide array from (array) accessor' do
      @presenter.foos.should == @array
    end
    
    it 'should provide nothing from #item accessor' do
      @presenter.item.should be_nil
    end
    
    it 'should use array.map(hash_for) for to_json' do
      @presenter.should_receive(:hash_for).twice.and_return({'bar'=>1}, {'bar'=>2})
      @presenter.to_json.should == %{[{"bar": 1}, {"bar": 2}]}
    end

    it 'should use hash_for(instance) for to_xml with model name' do
      @presenter.should_receive(:hash_for).twice.and_return({'bar'=>1}, {'bar'=>2})
      @presenter.to_xml(:indent=>0, :types=>false).should == %{<?xml version=\"1.0\" encoding=\"UTF-8\"?><foos type="array"><foo><bar type="integer">1</bar></foo><foo><bar type="integer">2</bar></foo></foos>}
    end
    
  end

end