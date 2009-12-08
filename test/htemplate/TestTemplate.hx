package htemplate;

import utest.Assert;

class TestTemplate
{
	var Template : Template;

	public function new();
	
	public function test_If_basic_vars_are_parsed_correctly()
	{
		Template = new Template('Hello {$name}');
		Assert.equals('Hello Boris', Template.execute( { name: 'Boris' } ));
	}

	public function test_If_basic_vars_are_parsed_correctly_with_hash()
	{
		var vars = new Hash<String>();
		vars.set('name', 'Boris');
		
		Template = new Template('Hello {$name}');
		Assert.equals('Hello Boris', Template.execute(vars));
	}
	
	public function test_If_basic_vars_are_parsed_correctly_with_whitespace()
	{
		Template = new Template("  Hello {$name}  \n ");
		Assert.equals("  Hello Boris  \n ", Template.execute( { name: 'Boris' } ));
	}
	
	public function test_If_keyword_vars_are_parsed_correctly()
	{
		Template = new Template("{#for(i in numbers)}{$i}-{#}");
		Assert.equals("1-2-3-4-5-", Template.execute( { numbers: [1, 2, 3, 4, 5] } ));
		
		Template = new Template("{#for(u in users)}{#if (u.name == 'Boris')}<b>{$u.name}</b>{#else if(u.name == 'Doris')}<i>{$u.name}</i>{#else}{$u.name}{#}<br>{#}");
		Assert.equals("<b>Boris</b><br><i>Doris</i><br>Someone else<br>", Template.execute({
			users: [{name: 'Boris'}, {name: 'Doris'}, {name: 'Someone else'}]
		}));
		
		Template = new Template("{? a = 10;}{#while(--a > 0)}{$a}{#}");
		Assert.equals("987654321", Template.execute());
	}
	
	public function test_If_captures_are_stored_correctly()
	{
		Template = new Template("1{!v}haxe{!}2{$v}3");
		Assert.equals("12haxe3", Template.execute());
		
		Template = new Template(" {!v}haxe{!} {$uc(v)} ");
		Assert.equals("  HAXE ", Template.execute( { uc : function(v) { return v.toUpperCase(); }}) );
		
		Template = new Template(" {!v1}ha{!v2}x{!}e{!} {$v1}{$v2}} ");
		Assert.equals("  haex} ", Template.execute());
	}
}