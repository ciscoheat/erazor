package erazor;

import utest.Assert;
import erazor.Output;
#if haxe3
import haxe.ds.StringMap in Hash;
#end

using erazor.Output;

class TestTemplate
{
	var template : Template;

	public function new(){}
	
	public function test_If_basic_vars_are_parsed_correctly()
	{
		template = new Template('Hello @name');
		Assert.equals('Hello Boris', template.execute( { name: 'Boris' } ));
	}

	public function test_If_basic_vars_are_parsed_correctly_with_hash()
	{
		var vars = new Hash<String>();
		vars.set('name', 'Boris');
		
		template = new Template('Hello @name');
		Assert.equals('Hello Boris', template.execute(vars));
	}
	
	public function test_If_basic_vars_are_parsed_correctly_with_whitespace()
	{
		template = new Template("  Hello @name  \n ");
		Assert.equals("  Hello Boris  \n ", template.execute( { name: 'Boris' } ));
	}
	
	public function test_If_keyword_vars_are_parsed_correctly()
	{
		template = new Template("@for(i in numbers){@(i)-}");
		Assert.equals("1-2-3-4-5-", template.execute( { numbers: [1, 2, 3, 4, 5] } ));

		template = new Template("@for(u in users){@if(u.name == 'Boris'){<b>@u.name</b>}else if(u.name == 'Doris'){<i>@u.name</i>}else{@u.name}<br>}");
		Assert.equals("<b>Boris</b><br><i>Doris</i><br>Someone else<br>", template.execute({
			users: [{name: 'Boris'}, {name: 'Doris'}, {name: 'Someone else'}]
		}));
		
		template = new Template("@{ a = 10; }@while(--a > 0){@a}");
		Assert.equals("987654321", template.execute());
		
		template = new Template("@{var a = 9; var b = '9'; while(--a > 0){b += a;} }@b");
		Assert.equals("987654321", template.execute());
	}
	
	public function test_If_HtmlTemplate_strings_are_escaped()
	{
		template = new HtmlTemplate("@text");
		Assert.equals("&lt; &gt; &amp; &quot; &#039;", template.execute( { text: "< > & \" '" } ));
		
		template = new HtmlTemplate("@for(u in users){<div>@u</div>}");
		Assert.equals("<div>admin</div><div>&lt;script&gt;</div>", template.execute( { users: ["admin","<script>",] } ));
	}
	
	public function test_If_HtmlTemplate_raw_works()
	{
		template = new HtmlTemplate("@raw(text)");
		Assert.equals("< > & \" '", template.execute( { text: "< > & \" '" } ));
		
		template = new HtmlTemplate("@for(u in users){<div>@raw(u)</div>}");
		Assert.equals("<div>admin</div><div><script></div>", template.execute( { users: ["admin", "<script>", ] } ));
		
		template = new HtmlTemplate("@raw(text)");
		Assert.equals("&lt; &gt; &amp; &quot; &#039;", template.execute( { text: new UnsafeString("< > & \" '") } ));
	}
	
	public function test_If_HtmlTemplate_SafeString_works()
	{
		template = new HtmlTemplate("@text");
		Assert.equals("< > & \" '", template.execute( { text: new SafeString("< > & \" '") } ));
		
		template = new HtmlTemplate("@for(u in users){<div>@u</div>}");
		Assert.equals("<div>admin</div><div><script></div>", template.execute( { users: ["admin".safe(), "<script>".safe()] } ));
	}

	/*
	public function test_If_captures_are_stored_correctly()
	{
		template = new Template("1{set v}haxe{end}2{:v}3");
		Assert.equals("12haxe3", template.execute());
		
		template = new Template(" {set v}haxe{end} {:uc(v)} ");
		Assert.equals("  HAXE ", template.execute( { uc : function(v) { return v.toUpperCase(); }}) );
		
		template = new Template(" {set v1}ha{set v2}x{end}e{end} {:v1}{:v2}} ");
		Assert.equals("  haex} ", template.execute());
	}
	*/
}
