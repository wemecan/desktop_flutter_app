import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:desktop_flutter_app/entity/ImageEntity.dart';
import 'package:extended_image/extended_image.dart';
import 'dart:ui';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:scoped_model/scoped_model.dart';

import 'model/app_state_model.dart';
import 'model/product.dart';

class PicSwiper extends StatefulWidget {
  final int index;
  final List<Product> pics;

  PicSwiper(this.index, this.pics);

  @override
  _PicSwiperState createState() => _PicSwiperState();
}

class _PicSwiperState extends State<PicSwiper>
    with SingleTickerProviderStateMixin {
  var rebuildIndex = StreamController<int>.broadcast();
  var rebuildSwiper = StreamController<bool>.broadcast();
  AnimationController _animationController;
  Animation<double> _animation;
  Function animationListener;
  List<double> doubleTapScales = <double>[1.0, 2.0];

  int currentIndex;
  bool _showSwiper = true;

  @override
  void initState() {
    currentIndex = widget.index;
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    rebuildIndex.close();
    rebuildSwiper.close();
    _animationController?.dispose();
    clearGestureDetailsCache();
    //cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    Widget result = Material(

        /// if you use ExtendedImageSlidePage and slideType =SlideType.onlyImage,
        /// make sure your page is transparent background
        color: Colors.black,
        shadowColor: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ExtendedImageGesturePageView.builder(
              itemBuilder: (BuildContext context, int index) {
                var path = widget.pics[index].fileSystemEntity.path;
                Widget image = ExtendedImage.file(
                  new File(path),
                  fit: BoxFit.contain,
                  enableSlideOutPage: true,
                  mode: ExtendedImageMode.Gesture,
                  initGestureConfigHandler: (state) {
                    double initialScale = 1.0;

                    if (state.extendedImageInfo != null &&
                        state.extendedImageInfo.image != null) {
                      initialScale = _initalScale(
                          size: size,
                          initialScale: initialScale,
                          imageSize: Size(
                              state.extendedImageInfo.image.width.toDouble(),
                              state.extendedImageInfo.image.height.toDouble()));
                    }
                    return GestureConfig(
                        inPageView: true,
                        initialScale: initialScale,
                        maxScale: max(initialScale, 5.0),
                        animationMaxScale: max(initialScale, 5.0),
                        //you can cache gesture state even though page view page change.
                        //remember call clearGestureDetailsCache() method at the right time.(for example,this page dispose)
                        cacheGesture: false);
                  },
                  onDoubleTap: (ExtendedImageGestureState state) {
                    ///you can use define pointerDownPosition as you can,
                    ///default value is double tap pointer down postion.
                    var pointerDownPosition = state.pointerDownPosition;
                    double begin = state.gestureDetails.totalScale;
                    double end;

                    //remove old
                    _animation?.removeListener(animationListener);

                    //stop pre
                    _animationController.stop();

                    //reset to use
                    _animationController.reset();

                    if (begin == doubleTapScales[0]) {
                      end = doubleTapScales[1];
                    } else {
                      end = doubleTapScales[0];
                    }

                    animationListener = () {
                      //print(_animation.value);
                      state.handleDoubleTap(
                          scale: _animation.value,
                          doubleTapPosition: pointerDownPosition);
                    };
                    _animation = _animationController
                        .drive(Tween<double>(begin: begin, end: end));

                    _animation.addListener(animationListener);

                    _animationController.forward();
                  },
                );
                image = GestureDetector(
                  child: image,
                  onTap: () {
                    Navigator.pop(context);
                  },
                );

                if (index == currentIndex) {
                  return Hero(
                    tag: path + index.toString(),
                    child: image,
                  );
                } else {
                  return image;
                }
              },
              itemCount: widget.pics.length,
              onPageChanged: (int index) {
                currentIndex = index;
                rebuildIndex.add(index);
              },
              controller: PageController(
                initialPage: currentIndex,
              ),
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              //physics: ClampingScrollPhysics(),
            ),
            StreamBuilder<bool>(
              builder: (c, d) {
                if (d.data == null || !d.data) return Container();

                return Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child:
                      MySwiperPlugin(widget.pics, currentIndex, rebuildIndex),
                );
              },
              initialData: true,
              stream: rebuildSwiper.stream,
            )
          ],
        ));

    return ExtendedImageSlidePage(
      child: result,
      slideAxis: SlideAxis.both,
      slideType: SlideType.onlyImage,
      onSlidingPage: (state) {
        ///you can change other widgets' state on page as you want
        ///base on offset/isSliding etc
        //var offset= state.offset;
        var showSwiper = !state.isSliding;
        if (showSwiper != _showSwiper) {
          // do not setState directly here, the image state will change,
          // you should only notify the widgets which are needed to change
          // setState(() {
          // _showSwiper = showSwiper;
          // });

          _showSwiper = showSwiper;
          rebuildSwiper.add(_showSwiper);
        }
      },
    );
  }

  double _initalScale({Size imageSize, Size size, double initialScale}) {
    var n1 = imageSize.height / imageSize.width;
    var n2 = size.height / size.width;
    if (n1 > n2) {
      final FittedSizes fittedSizes =
          applyBoxFit(BoxFit.contain, imageSize, size);
      //final Size sourceSize = fittedSizes.source;
      Size destinationSize = fittedSizes.destination;
      return size.width / destinationSize.width;
    } else if (n1 / n2 < 1 / 4) {
      final FittedSizes fittedSizes =
          applyBoxFit(BoxFit.contain, imageSize, size);
      //final Size sourceSize = fittedSizes.source;
      Size destinationSize = fittedSizes.destination;
      return size.height / destinationSize.height;
    }

    return initialScale;
  }
}

class MySwiperPlugin extends StatefulWidget {
  final List<Product> pics;
  final int index;
  final StreamController<int> reBuild;

  MySwiperPlugin(this.pics, this.index, this.reBuild);

  @override
  State<StatefulWidget> createState()=>new  _MySwiperPlugin();
}

class _MySwiperPlugin extends State<MySwiperPlugin> {
  var _addText= "添加";

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<int>(
      builder: (BuildContext context, data) {
        String path = widget.pics[data.data].fileSystemEntity.path;

        return DefaultTextStyle(
          style: TextStyle(color: Colors.white),
          child: Container(
            height: 50.0,
            width: double.infinity,
            color: Colors.grey.withOpacity(0.2),
            child: Row(
              children: <Widget>[
                Container(
                  width: 10.0,
                ),
                Text(
                  "${data.data + 1}",
                ),
                Text(
                  " / ${widget.pics.length}",
                ),
                Expanded(

                    child: Text(path.substring(path.lastIndexOf("/")) ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16.0, color: Colors.white))),
                Container(
                  width: 10.0,
                ),
                ScopedModelDescendant<AppStateModel>(
                  builder: (BuildContext context, Widget child,
                      AppStateModel model) {
                  final isAdd =  widget.pics[data.data].isAdd;
                    return GestureDetector(
                      child: Container(
                        padding: EdgeInsets.only(right: 10.0),
                        alignment: Alignment.center,
                        child: Text(
                          isAdd?"已添加":"添加",
                          style: TextStyle(fontSize: 16.0, color:isAdd? Colors.lightBlue: Colors.white),
                        ),
                      ),
                      onTap: () {
                        model.addProductToCart(widget.pics[data.data].id);
                        setState(() {
                          widget.pics[data.data].isAdd=true;
                        });
//                        _addText="已经添加";
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      initialData: widget.index,
      stream: widget.reBuild.stream,
    );
  }

}
