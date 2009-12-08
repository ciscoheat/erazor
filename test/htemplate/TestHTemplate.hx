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
	
	public function test_If_basic_vars_are_parsed_correctly_with_whitespace()
	{
		htemplate = new HTemplate("  Hello {$name}  \n ");
		Assert.equals("  Hello Boris  \n ", htemplate.execute( { name: 'Boris' } ));
	}
	
	public function test_If_keyword_vars_are_parsed_correctly()
	{
		htemplate = new HTemplate("{#for(i in numbers)}{$i}-{#}");
		Assert.equals("1-2-3-4-5-", htemplate.execute( { numbers: [1, 2, 3, 4, 5] } ));
		
		htemplate = new HTemplate("{#for(u in users)}{#if (u.name == 'Boris')}<b>{$u.name}</b>{#else if(u.name == 'Doris')}<i>{$u.name}</i>{#else}{$u.name}{#}<br>{#}");
		Assert.equals("<b>Boris</b><br><i>Doris</i><br>Someone else<br>", htemplate.execute({
			users: [{name: 'Boris'}, {name: 'Doris'}, {name: 'Someone else'}]
		}));
		
		htemplate = new HTemplate("{? a = 10;}{#while(--a > 0)}{$a}{#}");
		Assert.equals("987654321", htemplate.execute());
	}
}