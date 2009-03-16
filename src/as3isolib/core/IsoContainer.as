/*

as3isolib - An open-source ActionScript 3.0 Isometric Library developed to assist 
in creating isometrically projected content (such as games and graphics) 
targeted for the Flash player platform

http://code.google.com/p/as3isolib/

Copyright (c) 2006 - 2008 J.W.Opitz, All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/
package as3isolib.core
{
	import as3isolib.data.INode;
	import as3isolib.data.Node;
	import as3isolib.events.IsoEvent;
	import as3isolib.core.as3isolib_internal;
	
	import eDpLib.events.ProxyEvent;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	
	use namespace as3isolib_internal;
	
	/**
	 * IsoContainer is the base class that any isometric object must extend in order to be shown in the display list.
	 * Developers should not instantiate this class directly but rather extend it.
	 */
	public class IsoContainer extends Node implements IIsoContainer
	{
		//////////////////////////////////////////////////////////////////
		//	INCLUDE IN LAYOUT
		//////////////////////////////////////////////////////////////////
		
		/**
		 * @private
		 */
		protected var bIncludeInLayout:Boolean = true;
		
		/**
		 * @private
		 */
		protected var includeInLayoutChanged:Boolean = false;
		
		/**
		 * @private
		 */
		public function get includeInLayout ():Boolean
		{
			return bIncludeInLayout;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set includeInLayout (value:Boolean):void
		{
			if (bIncludeInLayout != value)
			{
				bIncludeInLayout = value;
				includeInLayoutChanged = true;
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		//	DISPLAY LIST CHILDREN
		////////////////////////////////////////////////////////////////////////
		
		protected var displayListChildrenArray:Array = [];
			
		/**
		 * @inheritDoc
		 */
		public function get displayListChildren ():Array
		{
			return displayListChildrenArray;
		}
		
		////////////////////////////////////////////////////////////////////////
		//	CHILD METHODS
		////////////////////////////////////////////////////////////////////////
			
			//	ADD
			////////////////////////////////////////////////////////////////////////
		
		/**
		 * @inheritDoc
		 */
		override public function addChildAt (child:INode, index:uint):void
		{
			if (child is IIsoContainer)
			{
				super.addChildAt(child, index);
				
				if (IIsoContainer(child).includeInLayout)
				{
					displayListChildrenArray.push(child);
					if (index > mainContainer.numChildren)
						index = mainContainer.numChildren;
					
					//referencing explicit removal of child RTE - http://life.neophi.com/danielr/2007/06/rangeerror_error_2006_the_supp.html
					var p:DisplayObjectContainer = IIsoContainer(child).container.parent;
					if (p && p != mainContainer)
						p.removeChild(IIsoContainer(child).container);
					
					mainContainer.addChildAt(IIsoContainer(child).container, index);
				}
			}
			
			else
				throw new Error("parameter child does not implement IContainer.");
		}
		
			//	SWAP
			////////////////////////////////////////////////////////////////////////
		
		/**
		 * @inheritDoc
		 */
		override public function setChildIndex (child:INode, index:uint):void
		{
			if (!child is IIsoContainer)
				throw new Error("parameter child does not implement IContainer.");
			
			else if (!child.hasParent || child.parent != this)
				throw new Error("parameter child is not found within node structure.");
			
			else
			{
				super.setChildIndex(child, index);
				mainContainer.setChildIndex(IIsoContainer(child).container, index);
			}
		}
			
			//	REMOVE
			////////////////////////////////////////////////////////////////////////
		
		/**
		 * @inheritDoc
		 */
		override public function removeChildByID (id:String):INode
		{
			var child:IIsoContainer = IIsoContainer(super.removeChildByID(id));
			if (child && child.includeInLayout)
			{
				var i:int = displayListChildrenArray.indexOf(child);
				if (i > -1)
					displayListChildrenArray.splice(i, 1);
				
				mainContainer.removeChild(IIsoContainer(child).container);
			}
			
			return child;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function removeAllChildren ():void
		{
			var child:IIsoContainer;
			for each (child in children)
			{
				if (child.includeInLayout)
					mainContainer.removeChild(child.container);
			}
			
			displayListChildrenArray = [];
				
			super.removeAllChildren();
		}		
			
			//	CREATE
			////////////////////////////////////////////////////////////////////////
		
		/**
		 * Initialization method to create the child IContainer objects.
		 */
		protected function createChildren ():void
		{
			//overriden by subclasses
			mainContainer = new Sprite();	
			//mainContainer.cacheAsBitmap = true;		
		}
		
		////////////////////////////////////////////////////////////////////////
		//	RENDER
		////////////////////////////////////////////////////////////////////////
		
		/**
		 * @inheritDoc
		 */
		public function render (recursive:Boolean = true):void
		{
			if (includeInLayoutChanged && parentNode)
			{
				var p:IIsoContainer = IIsoContainer(parentNode);
				var i:int = p.displayListChildren.indexOf(this);
				if (bIncludeInLayout)
				{
					if (i == -1)
						p.displayListChildren.push(this);
					
					if (!mainContainer.parent)
						IIsoContainer(parentNode).container.addChild(mainContainer);
				}
				
				else if (!bIncludeInLayout)
				{
					if (i >= 0)
						p.displayListChildren.splice(i, 1);
					
					if (mainContainer.parent)
						IIsoContainer(parentNode).container.removeChild(mainContainer);
				}
				
				includeInLayoutChanged = false;
			}
			
			if (recursive)
			{
				var child:IIsoContainer;
				for each (child in children)
					child.render(recursive);
			}
			
			dispatchEvent(new IsoEvent(IsoEvent.RENDER));
		}
		
		////////////////////////////////////////////////////////////////////////
		//	EVENT DISPATCHER PROXY
		////////////////////////////////////////////////////////////////////////
		
		/**
		 * @inheritDoc
		 */
		override public function dispatchEvent (event:Event):Boolean
		{
			//so we can make use of the bubbling events via the display list
			if (event.bubbles)
				return proxyTarget.dispatchEvent(new ProxyEvent(this, event));
				
			else
				return super.dispatchEvent(event);
		}
		
		////////////////////////////////////////////////////////////////////////
		//	CONTAINER STRUCTURE
		////////////////////////////////////////////////////////////////////////
		
		/**
		 * @private
		 */
		protected var mainContainer:Sprite;
		
		/**
		 * @inheritDoc
		 */
		public function get depth ():int
		{
			if (mainContainer.parent)
				return mainContainer.parent.getChildIndex(mainContainer);
			
			else
				return -1;
		}
		
		/**
		 * @inheritDoc
		 */
		[ClassUtil(ignore="true")]
		public function get container ():Sprite
		{
			return mainContainer;
		}
		
		////////////////////////////////////////////////////////////////////////
		//	CONSTRUCTOR
		////////////////////////////////////////////////////////////////////////
		
		/**
		 * Constructor
		 */
		public function IsoContainer()
		{
			super();
			createChildren();
			
			proxyTarget = mainContainer;
		}
	}
}