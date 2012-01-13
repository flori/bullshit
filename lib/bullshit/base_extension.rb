module Bullshit
  class BaseExtension < DSLKit::MethodMissingDelegator::DelegatorClass
    extend DSLKit::Constant
    extend DSLKit::DSLAccessor
    include DSLKit::BlockSelf
    include DSLKit::MethodMissingDelegator
    include CommonConstants
    include ModuleFunctions

    def initialize(&block)
      super(block_self(&block))
    end
  end
end
