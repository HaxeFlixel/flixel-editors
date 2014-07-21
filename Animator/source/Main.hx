package ;

import com.leveluplabs.tools.animator.GlobalData;
import com.leveluplabs.tools.animator.State_Init;
import com.leveluplabs.tools.animator.State_StressTest;
import crashdumper.CrashDumper;
import crashdumper.SessionData;
import flash.Lib;
import flixel.FlxG;
import flixel.FlxGame;
	
class Main extends FlxGame
{	
	public static var data:GlobalData;
	
	public function new()
	{
		#if HXCPP_DEBUGGER
		new org.flashdevelop.cpp.debugger.HaxeRemote(true, "127.0.0.1");
		#end
		
		#if crashdumper
			var c:CrashDumper = new CrashDumper(SessionData.generateID("animator"));
		#end

		data = new GlobalData();
		
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;
		var ratioX:Float = 1;// stageWidth / Lib.stage.stageWidth;
		var ratioY:Float = 1;// stageHeight / Lib.stage.stageHeight;
		var ratio:Float = Math.min(ratioX, ratioY);
		super(Math.floor(stageWidth / ratio), Math.floor(stageHeight / ratio), State_Init, ratio, 60, 60);
	}
}
