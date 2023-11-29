package ui.modal;

import dn.data.GetText.LocaleString;

typedef ContextActions = Array<ContextAction>;
typedef ContextAction = {
	var label : LocaleString;
	var ?icon : String;
	var ?subText : Null<LocaleString>;
	var ?className : String;
	var ?cb : Void->Void;
	var ?show : Void->Bool;
	var ?enable : Void->Bool;
	var ?separatorBefore: Bool;
	var ?separatorAfter: Bool;
	var ?subActions: ContextActions;
}

class ContextMenu extends ui.Modal {
	public static var ALL : Array<ContextMenu> = [];
	var jAttachTarget : js.jquery.JQuery; // could be empty

	public function new(?m:Coords, ?jNear:js.jquery.JQuery, ?openEvent:js.jquery.Event, isSubMenu=false) {
		super();

		if( !isSubMenu )
			closeAll();
		ALL.push(this);

		setTransparentMask();
		addClass("contextMenu");

		if( openEvent!=null || jNear!=null ) {
			var jEventTarget = jNear!=null ? jNear : new J(openEvent.target);
			jAttachTarget = jEventTarget;
			if( jAttachTarget.is("button.context") )
				jAttachTarget = jAttachTarget.parent();
			jAttachTarget.addClass("contextMenuOpen");

			if( jEventTarget.is("button") || jEventTarget.parent().is("button") || jNear!=null )
				setAnchor( MA_JQuery(jEventTarget) );
			else if( openEvent!=null )
				setAnchor( MA_Coords(new Coords(openEvent.pageX, openEvent.pageY)) );
		}
		else {
			jAttachTarget = new J("");
			if( m!=null )
				setAnchor( MA_Coords(m) );
		}
	}

	public function enableNoWrap() {
		jContent.addClass("noWrap");
	}

	public static function isOpen() {
		for(m in ALL)
			if( !m.destroyed )
				return true;
		return false;
	}

	public static function closeAll() {
		for(m in ALL)
			m.destroy();
	}

	override function onDispose() {
		super.onDispose();
		ALL.remove(this);
	}

	override function onClose() {
		super.onClose();
		jAttachTarget.removeClass("contextMenuOpen");
	}

	public static function addTo(jTarget:js.jquery.JQuery, showButton=true, ?jButtonContext:js.jquery.JQuery, actions:ContextActions) {
		// Cleanup
		jTarget
			.off(".context")
			.find("button.context").remove();

		// Open callback
		function _open(event:js.jquery.Event) {
			var ctx = new ContextMenu(event);
			for(a in actions)
				ctx.add(a);
		}

		// Menu button
		if( showButton ) {
			var jButton = new J('<button class="transparent context"/>');
			jButton.appendTo(jButtonContext==null ? jTarget : jButtonContext);
			jButton.append('<div class="icon contextMenu"/>');
			jButton.click( (ev:js.jquery.Event)->{
				ev.stopPropagation();
				_open(ev);
			});
		}

		// Right click
		jTarget.on("contextmenu.context", (ev:js.jquery.Event)->{
			ev.stopPropagation();
			ev.preventDefault();
			_open(ev);
		});
	}


	override function applyAnchor() {
		super.applyAnchor();

		var pad = 16;
		var docHei = App.ME.jDoc.innerHeight();

		if( jWrapper.offset().top < pad )
			jWrapper.css("top", pad+"px");

		if( jWrapper.offset().top + jWrapper.outerHeight() >= docHei-pad )
			jWrapper.css("bottom", pad+"px");
	}


	public function addTitle(str:LocaleString) {
		var jTitle = new J('<div class="title">$str</div>');
		jTitle.appendTo(jContent);
		applyAnchor();
	}

	public function add(a:ContextAction) {
		var jButton = new J('<button class="transparent"/>');
		if( a.show!=null && !a.show() )
			return jButton;
		jButton.appendTo(jContent);
		if( a.icon!=null )
			jButton.prepend('<span class="icon ${a.icon}"></span> ${a.label}');
		else
			jButton.html(a.label);

		if( a.subText!=null && a.subText!=a.label )
			jButton.append('<span class="sub">${a.subText}</span>');

		if( a.enable!=null && !a.enable() )
			jButton.prop("disabled", true);

		if( a.className!=null )
			jButton.addClass(a.className);

		jButton.click( (_)->{
			if( a.subActions==null )
				closeAll();
			else {
				addClass("subMenuOpen");
				var c = new ContextMenu(jButton, true);
				c.onCloseCb = ()->{
					removeClass("subMenuOpen");
				}
				for(subAction in a.subActions)
					c.add(subAction);
			}
			if( a.cb!=null )
				a.cb();
		});

		if( a.separatorBefore )
			jButton.addClass("separatorBefore");

		if( a.separatorAfter )
			jButton.addClass("separatorAfter");

		applyAnchor();
		return jButton;
	}
}