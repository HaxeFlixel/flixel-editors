package com.leveluplabs.tools.animator;
import flixel.FlxG;
import flixel.math.FlxRandom;
import flixel.editors.EntitySprite;
import flixel.editors.EntityGraphics;

class StressSprite extends EntitySprite
{
	public function new(X:Float,Y:Float,G:EntityGraphics) 
	{
		super(X, Y, G);
	}
	
	public function init(Offscreen:Bool = false):StressSprite
	{
		var speedMultiplier:Int = 50;
		
		if (Offscreen)
		{
			speedMultiplier = 5000;
		}
		
		velocity.x = speedMultiplier * FlxG.random.float( -5, 5);
		velocity.y = speedMultiplier * FlxG.random.float( -7.5, 2.5);
		acceleration.y = 5;
		elasticity = 1;
		
		return this;
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!State_StressTest.offscreen)
		{
			setBounds();
		}
	}

	function setBounds():Void
	{
		if (x+width > FlxG.width)
		{
			velocity.x *= -1;
			x = FlxG.width-width;
		}
		else if (x < 0)
		{
			velocity.x *= -1;
			x = 0;
		}
		
		if (y+height > FlxG.height)
		{
			velocity.y *= -0.8;
			y = FlxG.height-height;
		
			if (FlxG.random.sign() == 1)
			{
				velocity.y -= FlxG.random.float(3, 7);
			}
		}
		else if (y < 0)
		{
			velocity.y *= -0.8;
			y = 0;
		}
	}




}