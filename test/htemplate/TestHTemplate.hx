package htemplate;

import utest.Assert;

class TestHTemplate 
{
	var htemplate : HTemplate;

	public function new() 
	{
		
	}
	
	public function setup()
	{
		
	}
	
	public function test_If_basic_vars_are_parsed_correctly()
	{
		htemplate = new HTemplate('Hello {$name}');
		Assert.equals('Hello Boris', htemplate.execute( { name: 'Boris' } ));
	}

	public function test_If_basic_vars_are_parsed_correctly_with_hash()
	{
		var vars = new Hash<String>();
		vars.set('name', 'Boris');
		
		htemplate = new HTemplate('Hello {$name}');
		Assert.equals('Hello Boris', htemplate.execute(vars));
	}
}