require_relative '../ruby/helpers/paths_resolver'

libs = ["# generated by pro - any change will be overwritten",
        "# checkout file tools/starter/frontend_init.rb",
        "require 'imba'", "global.L = require 'lodash'"]
list = ["services/pro/index.coffee"] +
  PathsResolver.resolve('scss', sort: true) +
  PathsResolver.resolve('(jpe?g|png|gif|svg)') +
  PathsResolver.resolve('(imba|coffee)', blacklist: ['^services/pro/.*'], sort: :leafs_first)

list.map! do |line|
  "require '../../#{line}'"
end

def getter_class(ns, getter, order_by)
  extension = \
    if getter.s[:limit]
      if getter.s[:order][0][0] == :id
      then ".Static" else ".Dynamic" end
    end

  r  = getter.s[:relations].map{ |rel, g|
    "#{rel.to_s}:'#{$services.key(g).gsub(/^front\//, '')}'"
  }
  relations = "\n  @relations: {#{r.join(",")}}" if r.any?

  "class @['C'] extends Collection#{extension}
  @path: '#{ns}'
  @base: '#{getter.s[:base]}'
  @order: #{order_by}#{relations}
Collection.list['#{ns}'] = @['C']"
end

def read_order(order)
  case order
  when Symbol then order
  when Sequel::Postgres::JSONBOp then order.value.args[1]
  when Sequel::SQL::Cast then order.expr.value.args[1]
  end.to_s
end

getters = $services
  .select{ |_,v| v.superclass == Getter }
  .map { |ns, getter|
    order_by = getter.s[:order].map { |order, descending|
      [ if order.is_a? Sequel::SQL::OrderedExpression
        read_order(order.expression)
      else
        read_order(order)
      end, descending ].compact
    }
    getter_class ns.gsub(/^front\//, ''), getter, order_by
  }

start = ["require '../../services/pro/start.imba'"]

IO.write 'services/pro/init.coffee', (libs + list + getters + start).join("\n")
