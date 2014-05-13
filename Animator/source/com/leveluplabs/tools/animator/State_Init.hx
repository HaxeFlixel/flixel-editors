package com.leveluplabs.tools.animator;
import flash.errors.Error;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.U;
import flixel.editors.ColorIndex;
import flixel.FlxG;
import flixel.FlxState;
#if sys
	import systools.Dialogs;
	import sys.FileSystem;
	import sys.io.File;
	import sys.io.FileInput;
	import sys.io.FileOutput;
#end
import haxe.xml.Fast;
/**
 * ...
 * @author larsiusprime
 */
class State_Init extends FlxUIState
{
	public function new() 
	{
		super();
	}
	
	public override function create():Void
	{
		super.create();
		var ready:Bool = initData();
		if (ready)
		{
			startAnimator();
		}
	}
	
	public override function getEvent(name:String, sender:IFlxUIWidget, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		switch(name) {
			case "choose_path":
				#if debug
					trace("choose_path data = " + data);
				#end
				changeIndexPath(cast data);
				startAnimator();
		}
	}
	
	private function startAnimator():Void
	{
		Reg.color_index = Do.readColorIndex();
		FlxG.switchState(new State_Animator());
	}
	
	
	private function changeIndexPath(path:String):Void
	{
		Do.changeIndexPath(path);
	}
	
	private function initData():Bool
	{
		Reg.path_index = Do.readIndex();
		if (Reg.path_index == "") {
			openSubState(new Popup_Input());
			return false;
		}
		return true;
	}
	
	
}