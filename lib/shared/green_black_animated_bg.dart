import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';

/// Subtle animated background: black ↔ dark green gradient + slow moving
/// green light blobs (particles) with heavy blur to feel like lights behind glass.
class GreenBlackAnimatedBg extends StatefulWidget {
  const GreenBlackAnimatedBg({super.key, this.child});

  final Widget? child;

  @override
  State<GreenBlackAnimatedBg> createState() => _GreenBlackAnimatedBgState();
}

class _GreenBlackAnimatedBgState extends State<GreenBlackAnimatedBg>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Stack(
        fit: StackFit.expand,
        children: [
          // Subtle black → near-black-green gradient across the whole screen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 43, 46, 100), // pure black
                  Color.fromARGB(255, 45, 82, 142), // very dark green tint
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),

          // Green particles as moving light blobs
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                // Dimmer, larger soft lights spread across the screen
              baseColor: const Color.fromARGB(255, 181, 181, 181).withOpacity(0.22),
                spawnMinSpeed: 0.1,
                spawnMaxSpeed: 2.5,
                spawnMinRadius: 70.0,
                spawnMaxRadius: 180.0,
                particleCount: 20,
                image: null,
                opacityChangeRate: 0.01,
                minOpacity: 0.03,
                maxOpacity: 0.18,
              ),
              paint: Paint()
                ..blendMode = BlendMode.plus
                ..style = PaintingStyle.fill,
            ),
            child: const SizedBox.expand(),
          ),

          // Heavy blur layer to make blobs feel like soft lights behind glass
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withOpacity(0.03)),
          ),

          if (widget.child != null) widget.child!,
        ]);
  }
}


