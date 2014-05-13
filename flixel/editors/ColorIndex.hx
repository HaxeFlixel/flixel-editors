package flixel.editors;
import flixel.addons.ui.StrIdLabel;
import flixel.addons.ui.SwatchData;
import flixel.addons.ui.U;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.xml.Fast;

/**
 * Loads up all the color palette data in the game for easy referencing
 * 

 Expects an XML file in this basic format:
	 
 <?xml version="1.0" encoding="utf-8" ?>
 <data>
  	<palette_data>
		<palette name="rainbow">		<!--list of palettes referencing swatches-->
			<swatch name="red"/>
			<swatch name="orange"/>
			<swatch name="yellow"/>
			<swatch name="green"/>
		</palette>
	</palette_data>
	<swatch_data>						<!--list of swatches with up to 10 sub-colors-->
		<swatch name="red" c0="0xff5353" c1="0xfa0000" c2="0xc80000" c3="0xa80000"/>		can specify c0, c1, c2...c9
		<swatch name="orange" c0="0xff9854" c1="0xfa6400" c2="0xc85000" c3="0xa82400"/>
		<swatch name="yellow" c0="0xfffefe" c1="0xfff900" c2="0xd2c700" c3="0xb0a000"/>
		<swatch name="green" c0="0xacffa2" c1="0x1bfa00" c2="0x16c800" c3="0x08b000"/>
	</swatch_data>
 </data>

 *
 * @author larsiusprime
 */
class ColorIndex implements IFlxDestroyable
{
	public function new() 
	{
	}
	
	public function destroy():Void {
		if(_map_palettes != null){
			for (key in _map_palettes.keys()) {
				var arr:Array<String> = _map_palettes.get(key);
				_map_palettes.remove(key);
				U.clearArray(arr);
				arr = null;
			}
		}
		if(_map_swatches != null){
			for (key in _map_swatches.keys()) {
				_map_swatches.remove(key);
			}
		}
		_map_palettes = null;
		_map_swatches = null;
	}
	
	public function fromXML(xml:Fast):Void 
	{
		destroy();		//make sure it's cleared out
		
		_map_palettes = new Map<String,Array<String>>();
		_map_swatches = new Map<String,SwatchData>();
		
		if (xml.hasNode.swatch_data && xml.node.swatch_data.hasNode.swatch)
		{
			_loadSwatches(xml.node.swatch_data);
		}
		
		if (xml.hasNode.palette_data && xml.node.palette_data.hasNode.palette) 
		{
			_loadPalettes(xml.node.palette_data);
		}
	}
	
	/**
	 * Update the ColorIndex's information
	 * @param	list				list of new swatch data
	 * @param	forceMatchOnName	true: only update swatches with matching names in list; false: first update matches, then add non-matches as new entries. 
	 */
	
	public function updateFromSwatches(list:Array<SwatchData>,forceMatchOnName:Bool):Void{
		for (sd in list) {
			if (_map_swatches.exists(sd.name)) {
				var sd2:SwatchData = _map_swatches.get(sd.name);
				_map_swatches.remove(sd.name);
				sd2.destroy();
				sd2 = null;
				_map_swatches.set(sd.name,sd.copy());
			}else if (!forceMatchOnName) {
				_map_swatches.set(sd.name, sd.copy());
			}
		}
	}
	
	public function getSwatchList():Array<SwatchData> {
		var arr:Array<SwatchData> = [];
		for (key in _map_swatches.keys()) {
			var sd:SwatchData = _map_swatches.get(key);
			arr.push(sd.copy());
		}
		return arr;
	}
	
	public function getPaletteList():Array<StrIdLabel>{
		var arr:Array<StrIdLabel> = [];
		for (key in _map_palettes.keys()) {
			arr.push(new StrIdLabel(key, key));
		}
		return arr;
	}
	
	/**
	 * Returns a new color palette
	 * @param	str
	 * @return
	 */
	
	public function getPalette(str:String):ColorPalette
	{
		if (str == "" || str == "null") {
			return null;
		}
		
		if (_map_palettes.exists(str) == false) 
		{
			return null;
		}
		
		var list:Array<String> = _map_palettes.get(str);
		
		var swatches:Array<SwatchData> = [];
		for (sName in list) 
		{
			var swatch:SwatchData = getSwatch(sName);
			swatches.push(swatch);
		}
		
		return new ColorPalette(str, swatches);
	}
	
	/**
	 * Returns a copy of the color swatch stored internally by the given name
	 * @param	name
	 * @return
	 */
	
	public function getSwatch(name:String):SwatchData
	{
		if (_map_swatches.exists(name)) {
			var c:SwatchData = _map_swatches.get(name);
			return c.copy();
		}
		return null;
	}
	
	/**PRIVATE**/
	
	private var _map_palettes:Map<String,Array<String>>;
	private var _map_swatches:Map<String,SwatchData>;

	private function _loadSwatches(xml:Fast):Void 
	{
		for (swatchNode in xml.nodes.swatch)
		{
			var name:String = U.xml_str(swatchNode.x, "name", true);
			var colors:Array<Int> = [];
			for(i in 0...10){
				var iStr:String = "c"+Std.string(i);
				if(U.xml_str(swatchNode.x,iStr) != ""){
					var col:Int = U.parseHex(U.xml_str(swatchNode.x, iStr, true, "0x000000"), true, true);
					colors[i] = col;
				}else {
					colors[i] = 0x00000000;
				}
			}
			var swatch:SwatchData = new SwatchData(name, colors);
			_map_swatches.set(name, swatch);
		}
	}
	
	private function _loadPalettes(xml:Fast):Void 
	{
		for (paletteNode in xml.nodes.palette)
		{
			var name:String = U.xml_str(paletteNode.x, "name", true);
			if (paletteNode.hasNode.swatch)
			{
				var list:Array<String> = [];
				for (swatchNode in paletteNode.nodes.swatch)
				{
					var sName:String = U.xml_str(swatchNode.x, "name", true);
					list.push(sName);
				}
				_map_palettes.set(name, list);
			}
		}
	}
	
}