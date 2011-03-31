# Tokamak

Is a template engine for hypermedia resources that provides a single DSL to generate several media types representations.

This version supports json and xml generation (you can add other media types
easily)

The lib provide hooks for:

* Rails
* Sinatra
* Tilt ([https://github.com/rtomayko/tilt](https://github.com/rtomayko/tilt))

Just put `require "tokamak/hook/[sinatra|rails|tilt]"` on your app. See unit
tests for hook samples.

You are also able to implement hooks for other frameworks.

## Sample

The following DSL is a patch over the original DSL.

### Tokamak code

products {
  link "order", orders_url, "type" => "application/xml"
  
  @products.each do |prod|
    product {
      link   :self,  product_url(prod)
      id prod.id
      name prod.name
      price prod.price
    }
  end

}


Generates the following representations:

### JSON

{"products":
	{"link":[
		{"type":"application/xml",
		 "rel":"order",
		 "href":"http://localhost:3000/orders"}],
	"product":[
		{"link":
			[{"rel":"self",
			  "href":"http://localhost:3000/products/2",
			  "type":"application/json"}],
			 "id":2,
			 "name":"Rest Training (20h)",
			 "price":"800.0"},
		{"link":
			[{"rel":"self",
			  "href":"http://localhost:3000/products/3",
			  "type":"application/json"}],
		 	 "id":3,
		 	 "name":"Modern Software architecture and Design (20h)",
			 "price":"800.0"}
		]
	}
}

### XML

<?xml version="1.0"?>
<products>
  <link type="application/xml" rel="order" href="http://localhost:3000/orders"/>
  <product>
    <link rel="self" href="http://localhost:3000/products/2" type="application/xml"/>
    <id>2</id>
    <name>Rest Training (20h)</name>
    <price>800.0</price>
  </product>
  <product>
    <link rel="self" href="http://localhost:3000/products/3" type="application/xml"/>
    <id>3</id>
    <name>Modern Software architecture and Design (20h)</name>
    <price>800.0</price>
  </product>
</products>



## Other features

* You can declare recipes once and reuse it later (see `Tokamak::Recipes`)
* You can extend `Tokamak::Builder::Base` to support a custom media type.
* You can customize the DSL entrypoint helpers, used by the hooks (see `Tokamak::Builder::HelperTest`)

## Want to know more?

Please check the unit tests, you can see a lot of richer samples, including tests for the hooks.

*This library was extracted from [Restfulie](https://github.com/caelum/restfulie) and then heavy refactored. The same terms apply, see LICENSE.txt*

## A more complex example

order {
  
  link "self", order_url(@order)
  link "payment", order_payments_url(@order), "type" => "application/xml"
  link "calendar", order_calendar_url(@order), "type" => "text/calendar"

  address @order.address
  price @order.price
  state @order.state
  
  payments {
    @order.payments.each do |p|
      payment do 
        value  p.value
        state  p.state
      end
    end
  }

  items {
    @order.items.each do |i|
      item do
        id     i.product.id
        name   i.product.name
        price  i.product.price
        quantity  i.quantity
      end
    end
  }

}
