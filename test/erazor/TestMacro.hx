package erazor;
import utest.Assert;

/**
 * ...
 * @author Waneck
 */

class TestMacro 
{

	public function new() 
	{
		
	}
	
	public function test_If_basic_vars_are_parsed_correctly()
	{
		var template = new MacroTest0();
		Assert.equals('Hello Boris', template.execute( { name: 'Boris' } ));
	}
/*
	public function test_If_basic_vars_are_parsed_correctly_with_hash()
	{
		var vars = new Hash<String>();
		vars.set('name', 'Boris');
		
		var template = new MacroTest0();
		Assert.equals('Hello Boris', template.execute(vars));
	}
	*/
	public function test_If_basic_vars_are_parsed_correctly_with_whitespace()
	{
		var template = new MacroTest1();
		Assert.equals("  Hello Boris  \n ", template.execute( { name: 'Boris' } ));
	}
	
	public function test_If_keyword_vars_are_parsed_correctly()
	{
		var template = new MacroTest2();
		Assert.equals("1-2-3-4-5-", template.execute( { numbers: [1, 2, 3, 4, 5] } ));

		var template = new MacroTest3();
		Assert.equals("<b>Boris</b><br><i>Doris</i><br>Someone else<br>", template.execute({
			users: [{name: 'Boris'}, {name: 'Doris'}, {name: 'Someone else'}]
		}));
		
		var template = new MacroTest4();
		Assert.equals("987654321", template.execute({}));
		
		var template = new MacroTest5();
		Assert.equals("987654321", template.execute({}));
	}
}

@:template("Hello @name")
class MacroTest0 extends erazor.macro.Template<{name:String}>
{
	
}

@:template("  Hello @name  \n ")
class MacroTest1 extends erazor.macro.Template<{name:String}>
{
	
}

@:template("@for(i in numbers){@(i)-}")
class MacroTest2 extends erazor.macro.Template<{numbers:Array<Int>}>
{
	
}

@:template("@for(u in users){@if(u.name == 'Boris'){<b>@u.name</b>}else if(u.name == 'Doris'){<i>@u.name</i>}else{@u.name}<br>}")
class MacroTest3 extends erazor.macro.Template<{users:Array<{name:String}>}>
{
	
}

@:template("@{ a = 10; }@while(--a > 0){@a}")
class MacroTest4 extends erazor.macro.Template<Dynamic>
{
	
}

@:template("@{var a = 9; var b = '9'; while(--a > 0){b += a;} }@b")
class MacroTest5 extends erazor.macro.Template<Dynamic>
{
	
}