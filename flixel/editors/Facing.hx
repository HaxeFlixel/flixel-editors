package flixel.editors;

/**
 * ...
 * @author larsiusprime
 */
abstract Facing(Int) from Int to Int
{
	public static inline var NONE:Facing = FlxObject.NONE;
	
	//Directional constants:
	
	public static inline var LEFT:Facing = FlxObject.LEFT;
	public static inline var RIGHT:Facing = FlxObject.RIGHT;
	public static inline var UP:Facing = FlxObject.UP;
	public static inline var DOWN:Facing = FlxObject.DOWN;
	
	public static inline var UPPER_LEFT:Facing = FlxObject.LEFT | FlxObject.UP;
	public static inline var UPPER_RIGHT:Facing = FlxObject.RIGHT | FlxObject.UP;
	public static inline var LOWER_LEFT:Facing = FlxObject.LEFT | FlxObject.DOWN;
	public static inline var LOWER_RIGHT:Facing = FlxObject.RIGHT | FlxObject.DOWN;
	
	//Cardinal constants:
	
	public static inline var WEST:Facing = FlxObject.LEFT;
	public static inline var EAST:Facing = FlxObject.RIGHT;
	public static inline var NORTH:Facing = FlxObject.UP;
	public static inline var SOUTH:Facing = FlxObject.DOWN;
	
	public static inline var NORTH_WEST:Facing = FlxObject.LEFT | FlxObject.UP;
	public static inline var NORTH_EAST:Facing = FlxObject.RIGHT | FlxObject.UP;
	public static inline var SOUTH_WEST:Facing = FlxObject.LEFT | FlxObject.DOWN;
	public static inline var SOUTH_EAST:Facing = FlxObject.RIGHT | FlxObject.DOWN;
	
	public static function fromInt(Value:Int):Facing
	{
		switch(Value)
		{
			case LEFT: return LEFT;
			case RIGHT: return RIGHT;
			case UP: return UP;
			case DOWN: return DOWN;
			case UPPER_LEFT: return UPPER_LEFT;
			case UPPER_RIGHT: return UPPER_RIGHT;
			case LOWER_LEFT: return LOWER_LEFT;
			case LOWER_RIGHT: return LOWER_RIGHT;
		}
		return NONE;
	}
	
	public static function fromStr(str:String):Facing
	{
		//lowercase
		str = str.toLowerCase();
		
		//strip all common formatjunk
		while (str.indexOf("-") != -1){str = StringTools.replace(str, "-", "");}
		while (str.indexOf("_") != -1){str = StringTools.replace(str, "_", "");}
		while (str.indexOf(" ") != -1){str = StringTools.replace(str, " ", "");}
		while (str.indexOf("+") != -1) { str = StringTools.replace(str, "+", ""); }
		
		//accept all the most common synonyms
		switch(str)
		{
			case "l", "left", "w", "west": return LEFT;
			case "r", "right", "e", "east": return RIGHT;
			case "d", "down", "s", "south": return DOWN;
			case "u", "up", "n", "north": return NORTH;
			case "ul", "upleft", "upperleft", "nw", "northwest": return UPPER_LEFT;
			case "ur", "upright", "upperright", "ne", "northeast": return UPPER_RIGHT;
			case "ll", "dl", "downleft", "lowerleft", "sw", "southwest": return LOWER_LEFT;
			case "lr", "dr", "downright", "lowerright", "se", "southeast": return LOWER_RIGHT;
		}
		return NONE;
	}
	
	public function toCardinalStr():String
	{
		switch(this)
		{
			case WEST: return "west";
			case EAST: return "east";
			case NORTH: return "north";
			case SOUTH: return "south";
			case NORTH_WEST: return "north_west";
			case NORTH_EAST: return "north_east";
			case SOUTH_WEST: return "south_west";
			case SOUTH_EAST: return "south_east";
		}
		return "none";
	}
	
	public function toDirectionStr():String
	{
		switch(this)
		{
			case LEFT: return "left";
			case RIGHT: return "right";
			case UP: return "up";
			case DOWN: return "down";
			case LOWER_LEFT: return "lower_left";
			case LOWER_RIGHT: return "lower_right";
			case UPPER_LEFT: return "upper_left";
			case UPPER_RIGHT: return "upper_right";
		}
		return "none";
	}
}
