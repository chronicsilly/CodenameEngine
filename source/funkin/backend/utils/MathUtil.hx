package funkin.backend.utils;

import haxe.macro.Expr;

final class MathUtil {
	/**
	 * Returns the maximum value in the arguments.
	 * @param args Array of values
	 *
	 * @return The maximum value
	**/
	public static function maxInt(...args:Int):Int {
		var max = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg > max)
				max = arg;
		}
		return max;
	}

	/**
	 * Returns the minimum value in the arguments.
	 * @param args Array of values
	 *
	 * @return The minimum value
	**/
	public static function minInt(...args:Int):Int {
		var min = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg < min)
				min = arg;
		}
		return min;
	}

	/**
	 * Returns the maximum value in the arguments.
	 *
	 * NOTE: If you are using this in compile time, you should use `MathUtil.maxSmart` instead of this for better performance.
	 *
	 * @param args Array of values
	 *
	 * @return The maximum value
	**/
	public static function max(...args:Float):Float {
		var max = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg > max)
				max = arg;
		}
		return max;
	}

	/**
	 * Returns the minimum value in the arguments.
	 *
	 * NOTE: If you are using this in compile time, you should use `MathUtil.minSmart` instead of this for better performance.
	 *
	 * @param args Array of values
	 *
	 * @return The minimum value
	**/
	public static function min(...args:Float):Float {
		var min = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg < min)
				min = arg;
		}
		return min;
	}

	/**
	 * Shortcut to `Math.max` but with infinite amount of arguments
	 *
	 * Might not preserve the order of arguments, please test this.
	 *
	 * Dont use this in hscript, it doesnt work, it only works on compile time
	**/
	@:dox(hide) public static macro function maxSmart(..._args:Expr):Expr {
		return genericMinMaxSmart(_args.toArray(), "Math.max");
	}

	/**
	 * Shortcut to `Math.min` but with infinite amount of arguments
	 *
	 * Might not preserve the order of arguments, please test this.
	 *
	 * Dont use this in hscript, it doesnt work, it only works on compile time
	**/
	@:dox(hide) public static macro function minSmart(..._args:Expr):Expr {
		return genericMinMaxSmart(_args.toArray(), "Math.min");
	}

	#if macro
	@:dox(hide) private static function genericMinMaxSmart(_args:Array<Expr>, funcPath:String):Expr {
		var args = _args.copy();
		if (args.length == 0) return macro 0;

		var func = funcPath.split(".");

		function nested(lst:Array<Expr>):Expr {
			if (lst.length == 1) {
				return macro ${lst[0]};
			} else if (lst.length == 2) {
				return macro $p{func}(${lst[0]}, ${lst[1]});
			} else {
				var mid = Std.int(lst.length / 2);
				return macro $p{func}(${nested(lst.slice(0, mid))}, ${nested(lst.slice(mid, lst.length))});
			}
		}

		var expr = nested(args);

		//var printer = new haxe.macro.Printer();
		//trace(printer.printExpr(expr));

		return macro $expr;
	}
	#end
}