﻿import utest.ui.Report;
class TestAll
{
	static function main()
	{
		var runner = new utest.Runner();
		
		runner.addCase(new erazor.TestParser());
		runner.addCase(new erazor.TestScriptBuilder());
		runner.addCase(new erazor.TestTemplate());
		//runner.addCase(new erazor.TestEnhancedInterp());
		
		var report = Report.create(runner);
		runner.run();
	}
}