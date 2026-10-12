/// Fully customizable QR code generation for Flutter: independent corner
/// radii per module, per-module styling and pluggable renderers.
///
/// The camera scanner is a separate library, so apps that only generate
/// codes do not depend on the camera plugin's platforms:
/// `import 'package:flexi_qr_kit/scanner.dart';`.
library;

export 'src/core/exceptions/flexi_qr_exception.dart';
export 'src/core/models/qr_corner.dart';
export 'src/core/models/qr_error_correction_level.dart';
export 'src/core/models/qr_finder_position.dart';
export 'src/core/models/qr_module_context.dart';
export 'src/core/models/qr_module_type.dart';
export 'src/core/models/qr_neighbors.dart';
export 'src/core/models/qr_validation_result.dart';
export 'src/generator/encoder/qr_encoder.dart';
export 'src/generator/encoder/qr_package_encoder.dart';
export 'src/generator/export/qr_exporter.dart';
export 'src/generator/export/qr_image_renderer.dart';
export 'src/generator/matrix/qr_matrix.dart';
export 'src/generator/renderers/background/qr_background_renderer.dart';
export 'src/generator/renderers/finders/qr_finder_renderer.dart';
export 'src/generator/renderers/logo/qr_logo_layout.dart';
export 'src/generator/renderers/logo/qr_logo_renderer.dart';
export 'src/generator/renderers/modules/built_in_module_renderers.dart';
export 'src/generator/renderers/modules/module_geometry.dart';
export 'src/generator/renderers/modules/qr_module_renderer.dart';
export 'src/generator/renderers/qr_render_layout.dart';
export 'src/generator/renderers/qr_render_pipeline.dart';
export 'src/generator/smart_corners/qr_smart_corner_engine.dart';
export 'src/generator/styles/qr_corner_mode.dart';
export 'src/generator/styles/qr_design.dart';
export 'src/generator/styles/qr_finder_style.dart';
export 'src/generator/styles/qr_logo.dart';
export 'src/generator/styles/qr_module_shape.dart';
export 'src/generator/styles/qr_module_style.dart';
export 'src/generator/validation/qr_decoder.dart';
export 'src/generator/validation/qr_validator.dart';
export 'src/generator/widgets/flexi_qr_generator.dart';
export 'src/generator/widgets/flexi_qr_painter.dart';
