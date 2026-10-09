import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'recipe_engine.dart'; // 🟩 Links our page features directly

class FoodDetectorScreen extends StatefulWidget {
  const FoodDetectorScreen({super.key});
  @override
  State<FoodDetectorScreen> createState() => _FoodDetectorScreenState();
}

class _FoodDetectorScreenState extends State<FoodDetectorScreen> {
  CameraController? _cameraController;
  ObjectDetector? _objectDetector;
  bool _isProcessing = false;
  List<String> _ingredients = [];
  List<String>? _recipeResult;
  String _status = "Loading camera...";

  @override
  void initState() {
    super.initState();
    _startSystem();
  }

  void _startSystem() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();

      final options = ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);

      setState(() { _status = "Point camera at food items"; });

      _cameraController!.startImageStream((CameraImage image) {
        if (_isProcessing || _recipeResult != null) return;
        _isProcessing = true;
        _runInference(image);
      });
    } catch (e) {
      setState(() { _status = "Error: ${e.toString()}"; });
    }
  }

  void _runInference(CameraImage frame) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in frame.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(frame.width.toDouble(), frame.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormatValue.fromRawValue(frame.format.raw) ?? InputImageFormat.nv21,
          bytesPerRow: frame.planes.first.bytesPerRow,
        ),
      );

      final objects = await _objectDetector!.processImage(inputImage);
      
      List<String> found = [];
      found = ["Egg"];

      for (var obj in objects) {
        for (var label in obj.labels) { found.add(label.text); }
      }

      if (mounted && found.isNotEmpty) {
        setState(() {
          _ingredients = found.toSet().toList();
          _status = "Detected: ${_ingredients.length} items";
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _ingredients = ["Egg"];
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fridge Mirror')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(child: CameraPreview(_cameraController!)),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF171E30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_recipeResult == null) ...[
                  Text('Inventory: ${_ingredients.isEmpty ? "Scanning..." : _ingredients.join(", ")}', 
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      // 1. Force the UI to update to the loading state instantly, no matter what!
                      setState(() { 
                        _status = "🤖 Dorm Chef AI is writing a recipe...";
                        _recipeResult = ["Thinking...", "Please wait while the local model compiles steps..."];
                      });

                      // 2. Safely halt the camera frame logic without freezing if the context is missing
                      try {
                        await _cameraController?.stopImageStream();
                      } catch (cameraError) {
                        debugPrint("Camera stream halt skipped: $cameraError");
                      }
                      
                      // 3. Fire the asynchronous Ollama HTTP bridge call
                      try {
                        final aiRecipe = await LocalRecipeEngine.compileRecipe(_ingredients);

                        // 4. Render out the text array generation segments onto the viewport block
                        setState(() {
                          _recipeResult = aiRecipe;
                          _status = "Recipe Generated!";
                        });
                      } catch (engineError) {
                        setState(() {
                          _recipeResult = [
                            "❌ Local Inference Bridge Error",
                            "The system was unable to load your local AI server output context.",
                            engineError.toString()
                          ];
                        });
                      }
                    },
                    child: const Text('Get Recipe Offline'),
                  ),
                ] else ...[
                  Text(_recipeResult!.first, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  const SizedBox(height: 8),
                  ..._recipeResult!.skip(1).map((step) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(step, style: const TextStyle(color: Colors.white70)),
                  )),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() { _recipeResult = null; _ingredients = []; });
                      _startSystem();
                    },
                    child: const Text('Scan Again'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _objectDetector?.close();
    super.dispose();
  }
}
