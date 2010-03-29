package sizzle;

import js.Dom.Document;
import js.Dom.HtmlDom;
import js.Dom.HtmlCollection;

class Sizzle {
	//static public var myTrace = "";
	static private var initialized:Bool = false;

	static private var chunker:EReg = ~/((?:\((?:\([^()]+\)|[^()]+)+\)|\[(?:\[[^\[\]]*\]|['"][^'"]*['"]|[^\[\]'"]+)+\]|\\.|[^ >+~,(\[\\]+)+|[>+~])(\s*,\s*)?((?:.|\r|\n)*)/g;
	
	static private var done:Int = 0;
	static private var hasDuplicate:Bool = false;
	static private var baseHasDuplicate:Bool = true;
	
	static private var document = js.Lib.document;
	
	static public function init():Void {
		if (initialized) return;
		
		// Here we check if the JavaScript engine is using some sort of
		// optimization where it does not always call our comparision
		// function. If that is the case, discard the hasDuplicate value.
		//   Thus far that includes Google Chrome.
		[0, 0].sort(function(a:Int,b:Int):Int{
			baseHasDuplicate = false;
			return 0;
		});
		
		
		try {
			untyped Array.prototype.slice.call( document.documentElement.childNodes, 0 )[0].nodeType;
			
			makeArray = function(array:Dynamic,?results:Array<Dynamic> = null, ?debug:Bool = false):Array<Dynamic> {
				array = untyped Array.prototype.slice.call( array, 0 );
				if ( results != null ) {
					untyped results.push.apply( results, array );
					return results;
				}
	
				return array;
			};

		// Provide a fallback method if it does not work
		} catch(e:Dynamic){}
		
		/*Expr = {
			order:,
			match: new Hash<EReg>(),
			leftMatch: new Hash<EReg>(),
			attrMap: new Hash<String>(),
			attrHandle: new Hash<HtmlDom->String>(),
			relative: new Hash<Array<Dynamic>->String->Bool->Void>(),
			find: new Hash<Array<String>->Document->Bool->Array<HtmlDom>>(),
			preFilter: new Hash<Array<String>->Array<Dynamic>->Bool->Array<HtmlDom>->Bool->Bool->Dynamic>(),
			filters: new Hash<HtmlDom->Int->Dynamic->Bool>(),
			setFilters: new Hash<HtmlDom->Int->Dynamic->Array<HtmlDom>->Bool>(),
			filter: new Hash<HtmlDom->Dynamic->Int->Dynamic->Bool>()
		};*/
		
		_match.set("ID",~/#((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?![^\[]*\])(?![^\(]*\))/);
		_match.set("CLASS",~/\.((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?![^\[]*\])(?![^\(]*\))/);
		_match.set("NAME",~/\[name=['"]*((?:[\w\u00c0-\uFFFF\-]|\\.)+)['"]*\](?![^\[]*\])(?![^\(]*\))/);
		_match.set("ATTR",~/\[\s*((?:[\w\u00c0-\uFFFF\-]|\\.)+)\s*(?:(\S?=)\s*(['"]*)(.*?)\3|)\s*\](?![^\[]*\])(?![^\(]*\))/);
		_match.set("TAG",~/^((?:[\w\u00c0-\uFFFF\*\-]|\\.)+)(?![^\[]*\])(?![^\(]*\))/);
		_match.set("CHILD",~/:(only|nth|last|first)-child(?:\((even|odd|[\dn+\-]*)\))?(?![^\[]*\])(?![^\(]*\))/);
		_match.set("POS",~/:(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^\-]|$)(?![^\[]*\])(?![^\(]*\))/);
		_match.set("PSEUDO",~/:((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?:\((['"]?)((?:\([^\)]+\)|[^\(\)]*)+)\2\))?(?![^\[]*\])(?![^\(]*\))/);
		
		_leftMatch.set("ID",~/(^(?:.|\r|\n)*?)#((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?![^\[]*\])(?![^\(]*\))/);
		_leftMatch.set("CLASS",~/(^(?:.|\r|\n)*?)\.((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?![^\[]*\])(?![^\(]*\))/);
		_leftMatch.set("NAME",~/(^(?:.|\r|\n)*?)\[name=['"]*((?:[\w\u00c0-\uFFFF\-]|\\.)+)['"]*\](?![^\[]*\])(?![^\(]*\))/);
		_leftMatch.set("ATTR",~/(^(?:.|\r|\n)*?)\[\s*((?:[\w\u00c0-\uFFFF\-]|\\.)+)\s*(?:(\S?=)\s*(['"]*)(.*?)\4|)\s*\](?![^\[]*\])(?![^\(]*\))/);
		_leftMatch.set("TAG",~/(^(?:.|\r|\n)*?)^((?:[\w\u00c0-\uFFFF\*\-]|\\.)+)(?![^\[]*\])(?![^\(]*\))/);
		_leftMatch.set("CHILD",~/(^(?:.|\r|\n)*?):(only|nth|last|first)-child(?:\((even|odd|[\dn+\-]*)\))?(?![^\[]*\])(?![^\(]*\))/);
		_leftMatch.set("POS",~/(^(?:.|\r|\n)*?):(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^\-]|$)(?![^\[]*\])(?![^\(]*\))/);
		_leftMatch.set("PSEUDO",~/(^(?:.|\r|\n)*?):((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?:\((['"]?)((?:\([^\)]+\)|[^\(\)]*)+)\3\))?(?![^\[]*\])(?![^\(]*\))/);
		
		_attrMap.set("class","className");
		_attrMap.set("for","htmlFor");
		
		_attrHandle.set("href", function(elem:HtmlDom):String{
			return elem.getAttribute("href");
		});
		
		
		_relative.set("+", function(checkSet:Array<Dynamic>, part:String, isXML:Bool):Void{
			var isPartStr = Std.is(part,String),
				isTag = isPartStr && !~/\W/.match(part),
				isPartStrNotTag = isPartStr && !isTag;

			if ( isTag ) {
				part = part.toLowerCase();
			}

			var elem:Dynamic;
			for ( i in 0...checkSet.length ) {
				elem = checkSet[i];
				if ( elem != null ) {
					elem = elem.previousSibling;
					while ( (elem != null) && elem.nodeType != 1 ) {}

					checkSet[i] = isPartStrNotTag || elem != null && elem.nodeName.toLowerCase() == part ?
						elem != null :
						elem == part;
				}
			}

			if ( isPartStrNotTag ) {
				Sizzle.filter( part, checkSet, true );
			}
		});
		
		_relative.set(">", function(checkSet:Array<Dynamic>, part:Dynamic, isXML:Bool):Void{
			var isPartStr = Std.is(part,String),
				elem:Dynamic,
				i = 0,
				l = checkSet.length;

			if ( isPartStr && !~/\W/.match(part) ) {
				part = part.toLowerCase();

				while ( i < l ) {
					elem = checkSet[i];
					if ( elem ) {
						var parent = elem.parentNode;
						if (	parent.nodeName.toLowerCase() == part) {
							checkSet[i] = parent;
						} else {
							checkSet[i] = false;
						}
					}
					i++;
				}
			} else {
				while ( i < l ) {
					elem = checkSet[i];
					if ( elem ) {
						checkSet[i] = isPartStr ?
							elem.parentNode :
							elem.parentNode == part;
					}
					i++;
				}

				if ( isPartStr ) {
					Sizzle.filter( part, checkSet, true );
				}
			}
		});
		
		_relative.set("", function(checkSet:Array<Dynamic>, part:String, isXML:Bool):Void{
			var doneName = done++, 
				checkFn = dirCheck, 
				nodeCheck = null;

			if ( Std.is(part,String) && !~/\W/.match(part) ) {
				part = part.toLowerCase();
				nodeCheck = part;
				checkFn = dirNodeCheck;
			}

			checkFn("parentNode", part, Std.string(doneName), checkSet, nodeCheck, isXML);
		});
		
		_relative.set("~", function(checkSet:Array<Dynamic>, part:String, isXML:Bool):Void{
			var doneName = done++,
				checkFn = dirCheck,
				nodeCheck = null;

			if ( Std.is(part,String) && !~/\W/.match(part) ) {
				part = part.toLowerCase();
				nodeCheck = part;
				checkFn = dirNodeCheck;
			}

			checkFn("previousSibling", part, Std.string(doneName), checkSet, nodeCheck, isXML);
		});
		
		
		_find.set("ID", function(match:Array<String>, context:Document, isXML:Bool):Array<HtmlDom>{
			if ( context.getElementById != null && !isXML ) {
				var m = context.getElementById(match[1]);
				return m != null ? [m] : [];
			}
			return null;
		});
		
		_find.set("NAME", function(match:Array<String>, context:Document, isXML:Bool):Array<HtmlDom>{
			if ( context.getElementsByName != null ) {
				var ret = [], results = context.getElementsByName(match[1]);

				for ( i in 0...results.length ) {
					if ( results[i].getAttribute("name") == match[1] ) {
						ret.push( results[i] );
					}
				}

				return ret.length == 0 ? null : ret;
			}
			return null;
		});
		
		_find.set("TAG", function(match:Array<String>, context:Document, isXML:Bool):Array<HtmlDom>{
			return cast makeArray(context.getElementsByTagName(match[1]));
		});
		
		
		_preFilter.set("CLASS", function(match:Array<String>, curLoop:Array<Dynamic>, inplace:Bool, result:Array<Dynamic>, not:Bool, isXML:Bool):Dynamic{
			var _match = " " + ~/\\/g.replace(match[1],"") + " ";

			if ( isXML ) {
				return _match;
			}

			var i = 0, elem:Dynamic;
			while ( i < curLoop.length ) {
				elem = curLoop[i];
				if ( elem != null && elem != false ) {
					var b = (elem.className != null && ~/[\t\n]/g.replace(" " + elem.className + " ", " ").indexOf(_match) >= 0);
					if (not != b) {
						if ( !inplace ) {
							result.push( elem );
						}
					} else if ( inplace ) {
						curLoop[i] = false;
					}
				}
				i++;
			}

			return false;
		});
		
		_preFilter.set("ID", function(match:Array<String>, curLoop:Array<Dynamic>, inplace:Bool, result:Array<Dynamic>, not:Bool, isXML:Bool):Dynamic{
			return ~/\\/g.replace(match[1], "");
		});
		
		_preFilter.set("TAG", function(match:Array<String>, curLoop:Array<Dynamic>, inplace:Bool, result:Array<Dynamic>, not:Bool, isXML:Bool):Dynamic{
			return match[1].toLowerCase();
		});
	
		_preFilter.set("CHILD", function(match:Array<String>, curLoop:Array<Dynamic>, inplace:Bool, result:Array<Dynamic>, not:Bool, isXML:Bool):Dynamic{//if (match[0]==":nth-child(3)")js.Lib.alert(match);
			if ( match[1] == "nth" ) {
				// parse equations like 'even', 'odd', '5', '2n', '3n+2', '4n-1', '-n+6'
				var test = regexpAllMatched(~/(-?)(\d*)n((?:\+|-)?\d*)/,
											(match[2] == "even") ? "2n" : 
												((match[2] == "odd") ? "2n+1":
													((!~/\D/.match( match[2] )) ? ("0n+" + match[2]):
														match[2])
													)
												);

				// calculate the numbers (first)n+(last) including if they are negative
				match[2] = (test[1] + (test[2].length > 0 ? test[2] : '1'));
				match[3] = test[3];
			}

			// TODO: Move to normal caching system
			match[0] = Std.string(done++);

			return match;
		});
		
		_preFilter.set("ATTR", function(match:Array<String>, curLoop:Array<Dynamic>, inplace:Bool, result:Array<Dynamic>, not:Bool, isXML:Bool):Dynamic{
			var name = ~/\\/g.replace(match[1], "");
			
			if ( !isXML && _attrMap.exists(name) ) {
				match[1] = _attrMap.get(name);
			}

			if ( match[2] == "~=" ) {
				match[4] = " " + match[4] + " ";
			}

			return match;
		});
		
		_preFilter.set("PSEUDO", function(match:Array<String>, curLoop:Array<Dynamic>, inplace:Bool, result:Array<Dynamic>, not:Bool, isXML:Bool):Dynamic{
			if ( match[1] == "not" ) {
				// If we're dealing with a complex expression, or a simple one
				if ( ( chunker.match(match[3]) ? chunker.matched(0) : "" ).length > 1 || ~/^\w/.match(match[3]) ) {
					match[3] = Sizzle.select(match[3], null, null, curLoop);
				} else {
					var ret = Sizzle.filter(match[3], curLoop, inplace, !not);
					if ( !inplace ) {
						result.push( ret );
					}
					return false;
				}
			} else if ( _match.get("POS").match( match[0] ) || _match.get("CHILD").match( match[0] ) ) {
				return true;
			}
			
			return match;
		});
		
		_preFilter.set("POS", function(match:Array<String>, curLoop:Array<Dynamic>, inplace:Bool, result:Array<Dynamic>, not:Bool, isXML:Bool):Dynamic{
			match.unshift( "true" );
			return match;
		});
		
		
		_filters.set("enabled", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return input.disabled == false && input.type != "hidden";
		});
		
		_filters.set("disabled", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return input.disabled == true;
		});
		
		_filters.set("checked", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return input.checked == true;
		});
		
		_filters.set("selected", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			// Accessing this property makes selected-by-default
			// options in Safari work properly
			input.parentNode.selectedIndex;
			return input.selected == true;
		});
		
		_filters.set("parent", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			return elem.firstChild != null;
		});
		
		_filters.set("empty", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			return elem.firstChild == null;
		});
		
		_filters.set("has", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			return Sizzle.select( match[3], elem ).length > 0;
		});
		
		_filters.set("header", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			return (~/h\d/i).match( elem.nodeName );
		});
		
		_filters.set("text", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "text" == input.type;
		});
		
		_filters.set("radio", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "radio" == input.type;
		});
		
		_filters.set("checkbox", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "checkbox" == input.type;
		});
		
		_filters.set("file", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "file" == input.type;
		});
		
		_filters.set("password", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "password" == input.type;
		});
		
		_filters.set("submit", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "submit" == input.type;
		});
		
		_filters.set("image", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "image" == input.type;
		});
		
		_filters.set("reset", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "reset" == input.type;
		});
		
		_filters.set("button", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			var input:Dynamic = elem;
			return "button" == input.type || elem.nodeName.toLowerCase() == "button";
		});
		
		_filters.set("input", function(elem:HtmlDom, i:Int, match:Dynamic):Bool{
			return (~/input|select|textarea|button/i).match(elem.nodeName);
		});
		
		
		_setFilters.set("first", function(elem:HtmlDom, i:Int, match:Dynamic, array:Array<HtmlDom>):Bool{
			return i == 0;
		});
		
		_setFilters.set("last", function(elem:HtmlDom, i:Int, match:Dynamic, array:Array<HtmlDom>):Bool{
			return i == array.length - 1;
		});
		
		_setFilters.set("even", function(elem:HtmlDom, i:Int, match:Dynamic, array:Array<HtmlDom>):Bool{
			return i % 2 == 0;
		});
		
		_setFilters.set("odd", function(elem:HtmlDom, i:Int, match:Dynamic, array:Array<HtmlDom>):Bool{
			return i % 2 == 1;
		});
		
		_setFilters.set("lt", function(elem:HtmlDom, i:Int, match:Dynamic, array:Array<HtmlDom>):Bool{
			return i < Std.int(match[3]);
		});
		
		_setFilters.set("gt", function(elem:HtmlDom, i:Int, match:Dynamic, array:Array<HtmlDom>):Bool{
			return i > Std.int(match[3]);
		});
		
		_setFilters.set("nth", function(elem:HtmlDom, i:Int, match:Dynamic, array:Array<HtmlDom>):Bool{
			return Std.int(match[3]) == i;
		});
		
		_setFilters.set("eq", function(elem:HtmlDom, i:Int, match:Dynamic, array:Array<HtmlDom>):Bool{
			return Std.int(match[3]) == i;
		});
		
		_filter.set("PSEUDO", function(elem:HtmlDom, match:Dynamic, i:Int, array:Dynamic):Bool{
			//if (match[0] == ":header")js.Lib.alert(match);
			var name:String = match[1],
				filter = _filters.get(name),
				d:Dynamic = elem;

			if ( filter != null ) {
				return filter( elem, i, match/*, array*/ );
			} else if ( name == "contains" ) {
				var str:String;
				if (untyped elem.textContent) {
					str = untyped elem.textContent;
				} else if (untyped elem.innerText) {
					str = untyped elem.innerText;
				} else {
					str = Sizzle.getText([ elem ]);
				}
				return str.indexOf(match[3]) >= 0;
			} else if ( name == "not" ) {
				var not = match[3];

				for ( j in 0...not.length ) {
					if ( untyped not[j] == elem ) {
						return false;
					}
				}

				return true;
			} else {
				Sizzle.error( "Syntax error, unrecognized expression: " + name );
			}
			
			return false;
		});
		
		_filter.set("CHILD",function(elem:HtmlDom, match:Dynamic, i:Int, array:Dynamic):Bool{
			var type = match[1], node = elem;
			switch (type) {
				case 'only','first':
					while ( (node = node.previousSibling) != null )	 {
						if ( node.nodeType == 1 ) { 
							return false; 
						}
					}
					if ( type == "first" ) { 
						return true; 
					}
					node = elem;
					
					while ( (node = node.nextSibling) != null)	 {
						if ( node.nodeType == 1 ) { 
							return false; 
						}
					}
					return true;
				case 'last':
					while ( (node = node.nextSibling) != null )	 {
						if ( node.nodeType == 1 ) { 
							return false; 
						}
					}
					return true;
				case 'nth':
					var first = match[2], last = match[3];

					if ( first == '1' && last == '0' ) {
						return true;
					}
					
					var doneName = match[0],
						parent = elem.parentNode;
	
					if ( parent != null && (untyped parent.sizcache != doneName || untyped !elem.nodeIndex) ) {
						var count = 0;
						var node = parent.firstChild;
						while ( node != null ) {
							if ( node.nodeType == 1 ) {
								untyped node.nodeIndex = ++count;
							}
							node = node.nextSibling;
						} 
						untyped parent.sizcache = doneName;
					}
					
					var diff:Int = untyped elem.nodeIndex - Std.parseInt(last);
					if ( first == '0' ) {
						return diff == 0;
					} else {
						return ( diff % Std.parseInt(first) == 0 && diff / Std.parseInt(first) >= 0 );
					}
			}
			return false;
		});
		
		_filter.set("ID",function(elem:HtmlDom, match:Dynamic, i:Int, array:Dynamic):Bool{
			return elem.nodeType == 1 && elem.getAttribute("id") == match;
		});
		
		_filter.set("TAG",function(elem:HtmlDom, match:Dynamic, i:Int, array:Dynamic):Bool{
			return (match == "*" && elem.nodeType == 1) || elem.nodeName.toLowerCase() == match;
		});
		
		_filter.set("CLASS",function(elem:HtmlDom, match:Dynamic, i:Int, array:Dynamic):Bool{
			return (" " + (elem.className != null ? elem.className : elem.getAttribute("class")) + " ")
				.indexOf( match ) > -1;
		});
		
		_filter.set("ATTR",function(elem:HtmlDom, match:Dynamic, i:Int, array:Dynamic):Bool{
			var name = match[1],
				result = _attrHandle.exists(name) ?
					_attrHandle.get(name)( elem ) :
					untyped elem[name] ?
						untyped elem[name] :
						elem.getAttribute( name ),
				value = result + "",
				type = match[2],
				check = match[4];

			return result == null ?
				type == "!=" :
				type == "=" ?
				value == check :
				type == "*=" ?
				value.indexOf(check) >= 0 :
				type == "~=" ?
				(" " + value + " ").indexOf(check) >= 0 :
				(check == null || check.length == 0) ?
				value.length > 0 && result != "false" :
				type == "!=" ?
				value != check :
				type == "^=" ?
				value.indexOf(check) == 0 :
				type == "$=" ?
				value.substr(value.length - check.length) == check :
				type == "|=" ?
				value == check || value.substr(0, check.length + 1) == check + "-" :
				false;
		});
		
		_filter.set("POS",function(elem:HtmlDom, match:Dynamic, i:Int, array:Dynamic):Bool{
			var name = match[2], filter = _setFilters.get(name);

			if ( filter != null ) {
				return filter( elem, i, match, array );
			}
			return false;
		});
		
		//selectors = Expr;
		
		
		if ( untyped document.documentElement.compareDocumentPosition ) {
			sortOrder = function( a:Dynamic, b:Dynamic ):Int {
				if ( !a.compareDocumentPosition || !b.compareDocumentPosition ) {
					if ( a == b ) {
						hasDuplicate = true;
					}
					return a.compareDocumentPosition ? -1 : 1;
				}

				var ret = a.compareDocumentPosition(b) & 4 > 0 ? -1 : a == b ? 0 : 1;
				if ( ret == 0 ) {
					hasDuplicate = true;
				}
				return ret;
			};
		} else if ( untyped document.documentElement.sourceIndex ) {
			sortOrder = function( a:Dynamic, b:Dynamic ):Int {
				if ( !a.sourceIndex || !b.sourceIndex ) {
					if ( a == b ) {
						hasDuplicate = true;
					}
					return a.sourceIndex ? -1 : 1;
				}

				var ret:Int = Std.int(a.sourceIndex - b.sourceIndex);
				if ( ret == 0 ) {
					hasDuplicate = true;
				}
				return ret;
			};
		} else if ( untyped document.createRange ) {
			sortOrder = function( a:Dynamic, b:Dynamic ):Int {
				if ( !a.ownerDocument || !b.ownerDocument ) {
					if ( a == b ) {
						hasDuplicate = true;
					}
					return a.ownerDocument ? -1 : 1;
				}

				var aRange = a.ownerDocument.createRange(), bRange = b.ownerDocument.createRange();
				aRange.setStart(a, 0);
				aRange.setEnd(a, 0);
				bRange.setStart(b, 0);
				bRange.setEnd(b, 0);
				var ret = aRange.compareBoundaryPoints(untyped Range.START_TO_END, bRange);
				if ( ret == 0 ) {
					hasDuplicate = true;
				}
				return ret;
			};
		}
		
		// Check to see if the browser returns elements by name when
		// querying by getElementById (and provide a workaround)
		(function(){
			// We're going to inject a fake input element with a specified name
			var form = document.createElement("div"),
				id = "script" + Date.now().getTime();
			form.innerHTML = "<a name='" + id + "'/>";

			// Inject it into the root element, check its status, and remove it quickly
			var root = untyped document.documentElement;
			root.insertBefore( form, root.firstChild );

			// The workaround has to do additional checks after a getElementById
			// Which slows things down for other browsers (hence the branching)
			if ( document.getElementById( id ) != null ) {
				_find.set("ID", function(match:Array<String>, context:Document, isXML:Bool):Array<HtmlDom>{
					if ( context.getElementById != null && !isXML ) {
						var m = context.getElementById(match[1]);
						return m != null ? m.id == match[1] || (untyped m.getAttributeNode != null) && (untyped m.getAttributeNode("id").nodeValue == match[1]) ? [m] : null : [];
					}
					return [];
				});

				_filter.set("ID", function(elem:HtmlDom, match:Dynamic, i:Int, array:Dynamic):Bool{
					var node:HtmlDom = untyped elem.getAttributeNode != null ? untyped elem.getAttributeNode("id") : null;
					return node != null && elem.nodeType == 1 && node.nodeValue == match;
				});
			}

			root.removeChild( form );
			root = form = null; // release memory in IE
		})();
		
		(function(){
			// Check to see if the browser returns only elements
			// when doing getElementsByTagName("*")

			// Create a fake element
			var div = document.createElement("div");
			div.appendChild( untyped document.createComment("") );

			// Make sure no comments are found
			if ( div.getElementsByTagName("*").length > 0 ) {
				_find.set("TAG", function(match:Array<String>, context:Document, isXML:Bool):Array<HtmlDom>{
					var results:Array<HtmlDom> = cast makeArray(context.getElementsByTagName(match[1]));

					// Filter out possible comments
					if ( match[1] == "*" ) {
						var tmp = [];
						var i = 0;
						try{
							while ( results[i] != null ) {
								if ( results[i].nodeType == 1 ) {
									tmp.push( results[i] );
								}
								i++;
							}
						} catch (e:Dynamic){}

						results = tmp;
					}

					return results;
				});
			}

			// Check to see if an attribute returns normalized href attributes
			div.innerHTML = "<a href='#'></a>";
			if ( div.firstChild != null && div.firstChild.getAttribute != null &&
					div.firstChild.getAttribute("href") != "#" ) {
				_attrHandle.set("href", function(elem:HtmlDom):String{
					return untyped __js__('elem.getAttribute("href", 2)');
				});
			}

			div = null; // release memory in IE
		})();
		
		if ( untyped document.querySelectorAll ) {
			(function(){
				var oldSizzle = Sizzle.select, div = document.createElement("div");
				div.innerHTML = "<p class='TEST'></p>";

				// Safari can't handle uppercase or unicode characters when
				// in quirks mode.
				if ( untyped div.querySelectorAll && untyped div.querySelectorAll(".TEST").length == 0 ) {
					return;
				}
	
				Sizzle.select = function(query:String, ?context:HtmlDom, ?extra:Dynamic, ?seed:Dynamic):Dynamic {
					init();
					
					if (context == null) context = js.Lib.document;
					
//if (query=="#form select:first option:nth-child(3)")js.Lib.alert("here");
					// Only use querySelectorAll on non-XML documents
					// (ID selectors don't work in non-HTML documents)
					if ( !seed && context.nodeType == 9 && !Sizzle.isXML(context) ) {
						try {
							return makeArray( untyped context.querySelectorAll(query), extra );
						} catch(e:Dynamic){}
					}
		
					return oldSizzle(query, context, extra, seed);
				};

				div = null; // release memory in IE
			})();
		}

		try {
			(function(){
				var div = document.createElement("div");

				div.innerHTML = "<div class='test e'></div><div class='test'></div>";

				// Opera can't find a second classname (in 9.6)
				// Also, make sure that getElementsByClassName actually exists
				if (  untyped div.getElementsByClassName != null || untyped div.getElementsByClassName("e").length == 0 ) {
					return;
				}

				// Safari caches class attributes, doesn't catch changes (in 3.2)
				div.lastChild.className = "e";

				if ( untyped div.getElementsByClassName("e").length == 1 ) {
					return;
				}
	
				_order.insert(1, "CLASS");
				_find.set("CLASS", function(match:Array<String>, context:Document, isXML:Bool):Array<HtmlDom>{
					if ( untyped context.getElementsByClassName != null && !isXML ) {
						return untyped context.getElementsByClassName(match[1]);
					}
					return [];
				});

				div = null; // release memory in IE
			})();
		}catch (e:Dynamic){}
		
		initialized = true;
	}
	
	static private function saveGetMatched(regexp:EReg,idx:Int):String {
		var r:String = null;
		try {
			r = regexp.matched(idx);
		}catch(e:Dynamic){}
		return r;
	}
	
	dynamic static public function select(selector:String, ?context:HtmlDom, ?results:Dynamic, ?seed:Dynamic):Dynamic {
		init();

		if (results == null) results = [];
		if (context == null) context = js.Lib.document;

		var origContext = context;

		if ( context.nodeType != 1 && context.nodeType != 9 ) {
			return [];
		}
	
		if ( selector == null || selector.length == 0 || !Std.is(selector,String) ) {
			return results;
		}

		var parts = [],
			m, 
			set = null, 
			checkSet:Array<Dynamic> = null, 
			extra = null, 
			prune = true, 
			contextXML = Sizzle.isXML(context),
			soFar = selector,
			ret, 
			cur = null, 
			pop:Dynamic, 
			i;
		
		// Reset the position of the chunker regexp (start from head)
		chunker.match("");
		while ( chunker.match(soFar) ) {
			soFar = saveGetMatched(chunker,3);
	
			parts.push( saveGetMatched(chunker,1) );
			var tmp = saveGetMatched(chunker,2);
			if ( tmp != null && tmp.length > 0) {
				extra = saveGetMatched(chunker,3);
				break;
			}
			chunker.match("");
		}

		if ( parts.length > 1 && origPOS.match( selector ) ) {
			if ( parts.length == 2 && _relative.exists(parts[0]) ) { 
				set = posProcess( parts[0] + parts[1], context );
			} else {
				set = _relative.exists(parts[0]) ?
					[ context ] :
					Sizzle.select( parts.shift(), context );

				while ( parts.length > 0 ) {
					selector = parts.shift();

					if ( _relative.exists(selector) ) {
						selector += parts.shift();
					}
				
					set = posProcess( selector, set );
				}
			}
		} else {
			// Take a shortcut and set the context if the root selector is an ID
			// (but not if it'll be faster if the inner selector is an ID)
			if ( !seed && parts.length > 1 && context.nodeType == 9 && !contextXML &&
					_match.get("ID").match(parts[0]) && !_match.get("ID").match(parts[parts.length - 1]) ) {
				ret = Sizzle.find( parts.shift(), context, contextXML );
				context = ret.expr.length > 0 ? Sizzle.filter( ret.expr, ret.set )[0] : ret.set[0];
			}

			if ( context != null ) {
				ret = seed ?
					{ expr: parts.pop(), set: makeArray(seed) } :
					Sizzle.find( parts.pop(), parts.length == 1 && (parts[0] == "~" || parts[0] == "+") && context.parentNode != null ? context.parentNode : context, contextXML );//if (selector == ":header")js.Lib.alert(context.childNodes.length);
				set = ret.expr.length > 0 ? Sizzle.filter( ret.expr, ret.set ) : ret.set;
				//if (selector == "p > a")js.Lib.alert(set.length);
				if ( parts.length > 0 ) {
					checkSet = makeArray(set);
				} else {
					prune = false;
				}

				while ( parts.length > 0 ) {
					cur = parts.pop();
					pop = cur;

					if ( !_relative.exists(cur) ) {
						cur = "";
					} else {
						pop = parts.pop();
					}

					if ( pop == null ) {
						pop = context;
					}

					_relative.get(cur)( checkSet, pop, contextXML );
				}
			} else {
				checkSet = parts = [];
			}
		}

		if ( checkSet == null ) {
			checkSet = set;
		}

		if ( checkSet == null ) {
			Sizzle.error( (cur != null && cur.length > 0) ? cur : selector );
		}

		if ( Std.is(checkSet,Array) ) {
			if ( !prune ) {
				results.push.apply( results, checkSet );
			} else if ( context != null && context.nodeType == 1 ) {
				i = 0;
				while (checkSet[i] != null ) {//if (selector == "p > a")js.Lib.alert(checkSet[i].nodeType	);
					if ( checkSet[i] && (checkSet[i] == true || checkSet[i].nodeType == 1 && Sizzle.contains(context, checkSet[i])) ) {
						results.push( set[i] );
					}
					i++;
				}
			} else {
				i = 0;
				while (checkSet[i] != null ) {
					if ( checkSet[i] && checkSet[i].nodeType == 1 ) {
						results.push( set[i] );
					}
					i++;
				}
			}
		} else {
			makeArray( checkSet, results );
		}
//if (selector == "p > a")js.Lib.alert(results);
		if ( extra != null && extra.length > 0 ) {
			Sizzle.select( extra, origContext, results, seed );
			Sizzle.uniqueSort( results );
		}
//if (selector == "#main form#form > *:nth-child(2)")js.Lib.alert(results);
		return results;
	}
	
	static public function uniqueSort<T>(results:Array<T>):Array<T>{
		if ( sortOrder != null ) {
			hasDuplicate = baseHasDuplicate;
			results.sort(sortOrder);

			if ( hasDuplicate ) {
				var i = 0;
				while( i < results.length ) {
					if ( results[i] == results[i-1] ) {
						results.splice(i--, 1);
					}
					i++;
				}
			}
		}

		return results;
	}
	
	static public function matches(expr:String, set:Array<HtmlDom>):Array<HtmlDom>{
		init();
		return Sizzle.select(expr, null, null, set);
	}
	
	static public function find (expr:String, context:HtmlDom, isXML:Bool):{set:Array<HtmlDom>, expr:String} {
		init();//if (expr == ":header") js.Lib.alert(context.getElementsByTagName('*')[1000]);
		var set:Array<HtmlDom> = null;

		if ( expr == null || expr.length == 0 ) {
			return {set:null, expr:""};
		}

		for ( i in 0..._order.length ) {
			var type = _order[i], match;
		
			if ( (match = Sizzle.regexpAllMatched(_leftMatch.get(type),expr)).length > 0 ) {
				var left = match[1];
				match.splice(1,1);

				if ( left.substr( left.length - 1 ) != "\\" ) {
					match[1] = ~/\\/g.replace(match[1].length > 0 ? match[1] : "", "");
					set = _find.get(type)( match, cast context, isXML );
					if ( set != null ) {
						expr = _match.get(type).replace( expr, "" );
						break;
					}
				}
			}
		}

		if ( set == null ) {
			set = cast makeArray(context.getElementsByTagName("*"),null,expr == ":nth-child(2)");
		}
//if (expr == ":header") js.Lib.alert( context);
		return {set: set, expr: expr};
	}
	
	static public function filter(expr:String, set:Array<Dynamic>, ?inplace:Bool = false, ?not:Bool = false):Array<Dynamic>{
		init();
		var old = expr, result = [], curLoop = set, match:Dynamic, anyFound = null,
			isXMLFilter:Bool = set != null && set.length > 0 && Sizzle.isXML(set[0]);
//if (expr==":nth-child(3)")js.Lib.alert("here");
		while ( expr.length > 0 && set.length > 0 ) {
			var keyIter = _filter.keys();
			while ( keyIter.hasNext() ) {
				var type = keyIter.next();
				if ( (match = regexpAllMatched(_leftMatch.get(type),expr)).length > 2 ) {
					var filter = _filter.get(type), found = null, item:Dynamic, left = match[1];
					anyFound = false;

					match.splice(1,1);

					if ( left.substr( left.length - 1 ) == "\\" ) {
						continue;
					}

					if ( curLoop == result ) {
						result = [];
					}

					if ( _preFilter.exists(type) ) {
						match = _preFilter.get(type)( match, curLoop, inplace, result, not, isXMLFilter );

						if ( match == null || match == false || (match.length != null && match.length == 0) ) {
							anyFound = found = true;
						} else if ( match == true ) {
							continue;
						}
					}

					if ( match ) {
						var i = 0;
						while ( curLoop.length > i && (item = curLoop[i]) != null) {
							if ( item != null ) {
								found = filter( item, match, i, curLoop );
								var pass:Bool = not != found;

								if ( inplace && found ) {
									if ( pass ) {
										anyFound = true;
									} else {
										curLoop[i] = false;
									}
								} else if ( pass ) {
									result.push( item );
									anyFound = true;
								}
							}
							i++;
						}
					}

					if ( found != null ) {
						if ( !inplace ) {
							curLoop = result;
						}

						expr = _match.get(type).replace( expr, "" );

						if ( anyFound == null || !anyFound ) {
							return [];
						}

						break;
					}
				}
			}

			// Improper expression
			if ( expr == old ) {
				if ( anyFound == null ) {
					Sizzle.error( expr );
				} else {
					break;
				}
			}

			old = expr;
		}

		return curLoop;
	}
	
	static public function error( msg:String ):Void {
		throw "Syntax error, unrecognized expression: " + msg;
	}
	
	static private var _order:Array<String> = [ "ID", "NAME", "TAG" ];
	static private var _match = new Hash<EReg>();
	static private var _leftMatch = new Hash<EReg>();
	static private var _attrMap = new Hash<String>();
	static private var _attrHandle = new Hash<HtmlDom->String>();
	static private var _relative = new Hash<Array<Dynamic>->String->Bool->Void>();
	static private var _find = new Hash<Array<String>->Document->Bool->Array<HtmlDom>>();
	static private var _preFilter = new Hash<Array<String>->Array<Dynamic>->Bool->Array<HtmlDom>->Bool->Bool->Dynamic>();
	static private var _filters = new Hash<HtmlDom->Int->Dynamic->Bool>();
	static private var _setFilters = new Hash<HtmlDom->Int->Dynamic->Array<HtmlDom>->Bool>();
	static private var _filter = new Hash<HtmlDom->Dynamic->Int->Dynamic->Bool>();

	static public var selectors = {
		order: _order,
		match: _match,
		leftMatch: _leftMatch,
		attrMap: _attrMap,
		attrHandle: _attrHandle,
		relative: _relative,
		find: _find,
		preFilter: _preFilter,
		filters: _filters,
		setFilters: _setFilters,
		filter: _filter
	};
	
	inline static private var origPOS:EReg = ~/:(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^\-]|$)/;
	
	static private function regexpAllMatched(regexp:EReg, str:String):Array<String> {
		var match = new Array<String>();
		if (regexp.match(str)) {
			var n = 0;
			try {
				while(true) { match.push(regexp.matched(n++)); };
			} catch (e:Dynamic) {}
		}
		return match;
	}
	
	dynamic static public function makeArray(array:Dynamic,?results:Array<Dynamic> = null,?debug:Bool = false):Array<Dynamic> {
		var ret:Array<Dynamic> = results == null ? [] : results;//if (debug) js.Lib.alert("h");
		if (array == null) return ret;
		
		if ( Std.is(array,Array) ) {	
			for (e in cast(array,Array<Dynamic>)) {
				ret.push(e);
			}
		} else {
			var i = 0;
			if ( array.length != null && !Math.isNaN(array.length) ) {
				var l = untyped array.length;
				while (i<l) {
					ret.push( array[i++] );
				}
			} else {
				untyped __js__("for ( ; array[i]; i++ ) { ret.push( array[i] ); }");
			}
		}

		return ret;
	}
	
	static private var sortOrder:Dynamic->Dynamic->Int;
	
	static public function getText(elems:Array<HtmlDom>):String {
		init();
		var ret = "", elem;

		for (elem in elems) {
			// Get the text from text nodes and CDATA nodes
			if ( elem.nodeType == 3 || elem.nodeType == 4 ) {
				ret += elem.nodeValue;

			// Traverse everything else, except comment nodes
			} else if ( elem.nodeType != 8 ) {
				ret += Sizzle.getText( cast makeArray(elem.childNodes) );
			}
		}

		return ret;
	}
	
	static private function dirNodeCheck( dir:String , cur:String, doneName:String, checkSet:Array<Dynamic>, nodeCheck:Dynamic, isXML:Bool ):Void {
		for ( i in 0...checkSet.length ) {
			var elem:Dynamic = checkSet[i];
			if ( elem != null && elem != false ) {
				elem = Reflect.field(elem,dir);
				var match = false;

				while ( elem != null && elem != false ) {
					if ( untyped elem.sizcache == doneName ) {
						match = checkSet[elem.sizset];
						break;
					}

					if ( elem.nodeType == 1 && !isXML ){
						untyped elem.sizcache = doneName;
						elem.sizset = i;
					}

					if ( elem.nodeName.toLowerCase() == cur ) {
						match = elem;
						break;
					}

					elem = Reflect.field(elem,dir);
				}

				checkSet[i] = match;
			}
		}
	}
	
	static private function dirCheck( dir:String , cur:String, doneName:String, checkSet:Array<Dynamic>, nodeCheck:Dynamic, isXML:Bool ):Void {
		for ( i in 0...checkSet.length) {
			var elem:Dynamic = checkSet[i];
			if ( elem != null && elem != false ) {
				elem = Reflect.field(elem,dir);
				var match = false;

				while ( elem != null && elem != false ) {
					if ( elem.sizcache == doneName ) {
						match = checkSet[elem.sizset];
						break;
					}

					if ( elem.nodeType == 1 ) {
						if ( !isXML ) {
							elem.sizcache = doneName;
							elem.sizset = i;
						}
						if ( !Std.is(cur,String) ) {
							if ( elem == cur ) {
								match = true;
								break;
							}

						} else if ( Sizzle.filter( cur, [elem] ).length > 0 ) {
							match = elem;
							break;
						}
					}

					elem = Reflect.field(elem,dir);
				}

				checkSet[i] = match;
			}
		}
	}
	
	static public var contains:Dynamic->Dynamic->Bool = untyped js.Lib.document.compareDocumentPosition != null ? function(a:Dynamic, b:Dynamic):Bool{
		return !!(a.compareDocumentPosition(b) & 16 > 0);
	} : function(a, b){
		return a != b && (a.contains != null ? untyped a.contains(b) : true);
	};
	
	static public function isXML(elem:Dynamic):Bool{
		// documentElement is verified for cases where it doesn't yet exist
		// (such as loading iframes in IE - #4833) 
		var documentElement:HtmlDom = elem != null ? elem.ownerDocument != null ? elem.ownerDocument : elem : null;
		documentElement = documentElement != null ? untyped documentElement.documentElement : null;
		return documentElement != null ? documentElement.nodeName != "HTML" : false;
	}
	
	static private function posProcess(selector:String, context:Dynamic):Array<Dynamic>{
		var tmpSet = [], later = "", match,
			root:Dynamic = context.nodeType > 0 ? [context] : context;

		// Position selectors must be done after the filter
		// And so must :not(positional) so we move all PSEUDOs to the end
		var reg = _match.get("PSEUDO");
		while (reg.match(selector)) {
			later += reg.matched(0);
			selector = reg.replace( selector, "" );
		}

		selector = _relative.exists(selector) ? selector + "*" : selector;

		for ( i in 0...root.length ) {
			Sizzle.select( selector, root[i], tmpSet );
		}

		return Sizzle.filter( later, tmpSet );
	}
	
	static private function main():Void {
		init();
	}
}
