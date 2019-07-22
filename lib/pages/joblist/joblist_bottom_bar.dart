import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';
import 'package:flutter/material.dart';

class JoblistBottomBar extends StatelessWidget {
  static final double opacity = .2;
  static final BorderRadius borderRadius = BorderRadius.vertical(top: Radius.circular(16));
  static final double elevation = 16.0;
  final BuildContext context;
  final String lockedPrinter;
  final void Function(int) onPressed;
  final int current;

  JoblistBottomBar(this.context, {this.lockedPrinter, this.onPressed, this.current});

  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  List<BubbleBottomBarItem> get items => <BubbleBottomBarItem>[
        BubbleBottomBarItem(
          backgroundColor: Colors.red,
          icon: Icon(
            Icons.cancel,
            color: Theme.of(context).textTheme.title.color,
          ),
          activeIcon: Icon(
            Icons.list,
            color: Colors.redAccent,
          ),
          title: Text("Liste"),
        ),
        BubbleBottomBarItem(
          backgroundColor: Colors.deepPurple,
          icon: Column(
            children: <Widget>[
              Icon(
                Icons.scanner,
                size: 16.0,
                color: Theme.of(context).textTheme.title.color,
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 16.0,
                color: Theme.of(context).textTheme.title.color,
              ),
              Icon(
                Icons.picture_as_pdf,
                size: 16.0,
                color: Theme.of(context).textTheme.title.color,
              ),
            ],
          ),
          activeIcon: Row(
            children: <Widget>[
              Icon(
                Icons.scanner,
                color: Colors.deepPurpleAccent,
              ),
              Icon(
                Icons.arrow_forward,
                size: 16.0,
                color: Colors.deepPurpleAccent,
              ),
              Icon(
                Icons.picture_as_pdf,
                color: Colors.deepPurpleAccent,
              ),
            ],
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Scanner"),
              Text(lockedPrinter ?? 'Keiner}', textScaleFactor: 0.7),
            ],
          ),
        ),
        BubbleBottomBarItem(
          backgroundColor: Colors.indigo,
          icon: Column(
            children: <Widget>[
              Icon(
                Icons.scanner,
                size: 16.0,
                color: Theme.of(context).textTheme.title.color,
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 16.0,
                color: Theme.of(context).textTheme.title.color,
              ),
              Icon(
                Icons.print,
                size: 16.0,
                color: Theme.of(context).textTheme.title.color,
              ),
            ],
          ),
          activeIcon: Row(
            children: <Widget>[
              Icon(
                Icons.scanner,
                color: Colors.indigoAccent,
              ),
              Icon(
                Icons.arrow_forward,
                size: 16.0,
                color: Colors.indigoAccent,
              ),
              Icon(
                Icons.print,
                color: Colors.indigoAccent,
              ),
            ],
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Kopierer:"),
              Text(lockedPrinter ?? 'Keiner', textScaleFactor: 0.7),
            ],
          ),
        ),
      ];


  @override
  Widget build(BuildContext context) {
    return BubbleBottomBar(
      items: items,
      opacity: opacity,
      onTap: onPressed,
      currentIndex: current,
      elevation: elevation,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );
  }
}
