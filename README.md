[![Build Status](https://travis-ci.org/felixflores/railway_operation.svg?branch=master)](https://travis-ci.org/felixflores/railway_operation)

# RailwayOperation

This gem allows you to declare and compose a set of operations into an function execution tree inspired by the railway oriented programming pattern ([https://fsharpforfunandprofit.com/rop/](https://fsharpforfunandprofit.com/rop/)) for more details.

## Basic Usage
Let's say we have the following class

```ruby
module Readme
  class Synopsis
    def initialize(someone = 'someone')
      @someone = someone
    end

    def first_method(argument)
      argument << "Hello #{@someone}, from first_method."
    end

    def another_method(argument)
      argument << 'Hello from another_method.'
    end

    def final_method(argument)
      argument << 'Hello from final_method.'
    end
  end
end
```

We could perform the follow set of operations

```ruby
synopsis = Readme::Synopsis.new('Felix')
argument = []

result = synopsis.first_method([])
result = synopsis.another_method(result)
result = synopsis.final_method(result)

result == [
  'Hello Felix, from first_method.'
  'Hello from another_method.'
  'Hello from final_method.'
]
```

RailwayOperation provides a way for you to declare the same execution chain as a series of steps in an operation. By doing `include RailwayOperation::Operator` to your class, the `.add_step` class method is made available and a corresponding `#run` and `.run` method will execution chain will be performed.

```ruby
module Readme
  class Synopsis
    include RailwayOperation::Operator

    add_step 0, :first_method
    add_step 0, :another_method
    add_step 0, :final_method

    def first_method(argument)
      argument << 'Hello from first_method.'
    end

    def another_method(argument)
      argument << 'Hello from another_method.'
    end

    def final_method(argument)
      argument << 'Hello from final_method.'
    end
  end
end

result = Readme::Synopsis.new('Felix').run(argument)

result == [
  'Hello Felix, from first_method.'
  'Hello from another_method.'
  'Hello from final_method.'
]
```

Additionally, if your class does not require any arguments in its initializer you can call

```ruby
result = Readme::Synopsis.run(argument)
```

## Handling Exceptions
Let's say we want to log an error in case something goes wrong along the execution chain.

```ruby
module Readme
  class Synopsis
    include RailwayOperation::Operator
    class MyError < StandardError; end

    add_step 0, :first_method
    add_step 0, :another_method
    add_step 0, :final_method

    def first_method(argument)
      argument << 'Hello from first_method.'
    end

    def another_method(argument)
      argument << 'Hello from another_method.'
      raise MyError
    end

    def final_method(argument)
      argument << 'Hello from final_method.'
    end
  end
end

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'railway_operation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install railway_operation
    
Then in any of your ruby class `include RailwayOperation::Operator`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/railway_operation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

