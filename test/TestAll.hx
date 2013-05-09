import utest.ui.Report;
class TestAll
{
	static function main()
	{
		var runner = new utest.Runner();
		
		runner.addCase(new erazor.TestParser());
		runner.addCase(new erazor.TestMacro());
		runner.addCase(new erazor.TestSimpleMacro());
		runner.addCase(new erazor.TestScriptBuilder());
		runner.addCase(new erazor.TestTemplate());
		
		var report = Report.create(runner);
		runner.run();
	}
}