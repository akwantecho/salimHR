import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_text.dart';
import '../i18n.dart';

/// A file/image the user chose to attach (kept in memory as bytes).
class PickedAttachment {
  final Uint8List bytes;
  final String filename;
  final bool isImage;

  const PickedAttachment({
    required this.bytes,
    required this.filename,
    required this.isImage,
  });
}

/// Prompts the user to attach from camera, gallery or a file, then returns the
/// chosen attachment (or null if cancelled).
Future<PickedAttachment?> pickAttachment(BuildContext context) async {
  final source = await Navigator.of(context).push<String>(
    PageRouteBuilder(
      opaque: false,
      barrierColor: const Color(0x66000000),
      barrierDismissible: true,
      pageBuilder: (context, _, _) => const _AttachmentSourceSheet(),
    ),
  );
  if (source == null) return null;

  if (source == 'camera' || source == 'gallery') {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    return PickedAttachment(bytes: bytes, filename: x.name, isImage: true);
  }

  // Arbitrary file (PDF, doc, ...).
  final res = await FilePicker.platform.pickFiles(withData: true);
  if (res == null || res.files.isEmpty) return null;
  final f = res.files.first;
  if (f.bytes == null) return null;
  final isImg =
      RegExp(r'\.(jpg|jpeg|png|webp)$', caseSensitive: false).hasMatch(f.name);
  return PickedAttachment(bytes: f.bytes!, filename: f.name, isImage: isImg);
}

/// Row that either offers to attach (when [attachment] is null) or previews the
/// chosen attachment with a remove button. Reused by the note form and the
/// admin reply sheet.
class AttachmentField extends StatelessWidget {
  final PickedAttachment? attachment;
  final VoidCallback onAttach;
  final VoidCallback onRemove;

  const AttachmentField({
    super.key,
    required this.attachment,
    required this.onAttach,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (attachment == null) {
      return GestureDetector(
        onTap: onAttach,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsetsDirectional.all(ds.spacing.md),
          decoration: BoxDecoration(
            color: ds.colors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(ds.radii.large),
            border: Border.all(color: ds.colors.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              DSLineIcon(
                type: LineIconType.bookmark,
                color: ds.colors.primary,
                size: ds.spacing.md,
              ),
              SizedBox(width: ds.spacing.sm),
              DSText(
                t('إرفاق صورة أو ملف', 'Attach a photo or file'),
                role: DSTextRole.label,
                color: ds.colors.primary,
              ),
            ],
          ),
        ),
      );
    }

    final att = attachment!;
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.sm),
      decoration: BoxDecoration(
        color: ds.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ds.radii.medium),
            child: att.isImage
                ? Image.memory(att.bytes,
                    width: ds.spacing.xl, height: ds.spacing.xl, fit: BoxFit.cover)
                : Container(
                    width: ds.spacing.xl,
                    height: ds.spacing.xl,
                    color: ds.colors.primary.withValues(alpha: 0.12),
                    child: Center(
                      child: DSText('FILE',
                          role: DSTextRole.caption, color: ds.colors.primary),
                    ),
                  ),
          ),
          SizedBox(width: ds.spacing.sm),
          Expanded(
            child: DSText(att.filename, role: DSTextRole.caption, maxLines: 1),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsetsDirectional.all(ds.spacing.xs),
              child: DSLineIcon(
                type: LineIconType.trash,
                color: const Color(0xFFEF4444),
                size: ds.spacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a note/reply's server attachment (image thumbnail or file chip).
/// Tapping opens it externally.
class NoteAttachmentChip extends StatelessWidget {
  final String url;
  final String? name;
  final bool isImage;

  const NoteAttachmentChip({
    super.key,
    required this.url,
    this.name,
    required this.isImage,
  });

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    Widget fileBox() => Container(
          width: ds.spacing.xl,
          height: ds.spacing.xl,
          color: ds.colors.primary.withValues(alpha: 0.12),
          child: Center(
            child: DSText('FILE',
                role: DSTextRole.caption, color: ds.colors.primary),
          ),
        );

    return GestureDetector(
      onTap: _open,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsetsDirectional.only(top: ds.spacing.sm),
        padding: EdgeInsetsDirectional.all(ds.spacing.sm),
        decoration: BoxDecoration(
          color: ds.colors.surfaceAlt,
          borderRadius: BorderRadius.circular(ds.radii.medium),
          border: Border.all(color: ds.colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ds.radii.medium),
              child: isImage
                  ? Image.network(
                      url,
                      width: ds.spacing.xl,
                      height: ds.spacing.xl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fileBox(),
                    )
                  : fileBox(),
            ),
            SizedBox(width: ds.spacing.sm),
            Expanded(
              child: DSText(
                name ?? t('مرفق', 'Attachment'),
                role: DSTextRole.caption,
                maxLines: 1,
              ),
            ),
            DSText(t('عرض', 'View'),
                role: DSTextRole.caption, color: ds.colors.primary),
          ],
        ),
      ),
    );
  }
}

class _AttachmentSourceSheet extends StatelessWidget {
  const _AttachmentSourceSheet();

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    Widget option(String value, LineIconType icon, String label) =>
        GestureDetector(
          onTap: () => Navigator.of(context).pop(value),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: ds.spacing.md),
            child: Row(
              children: [
                Container(
                  width: ds.spacing.xl,
                  height: ds.spacing.xl,
                  decoration: BoxDecoration(
                    color: ds.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(ds.radii.medium),
                  ),
                  child: Center(
                    child: DSLineIcon(
                      type: icon,
                      color: ds.colors.primary,
                      size: ds.spacing.md,
                    ),
                  ),
                ),
                SizedBox(width: ds.spacing.md),
                DSText(label, role: DSTextRole.title),
              ],
            ),
          ),
        );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsetsDirectional.fromSTEB(
          ds.spacing.lg,
          ds.spacing.lg,
          ds.spacing.lg,
          ds.spacing.xl,
        ),
        decoration: BoxDecoration(
          color: ds.colors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ds.radii.xLarge),
            topRight: Radius.circular(ds.radii.xLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DSText(t('إرفاق', 'Attach'), role: DSTextRole.headline),
              SizedBox(height: ds.spacing.sm),
              option('camera', LineIconType.calendar,
                  t('التقاط صورة', 'Take a photo')),
              option('gallery', LineIconType.heart,
                  t('اختيار صورة', 'Choose a photo')),
              option('file', LineIconType.bookmark,
                  t('اختيار ملف', 'Choose a file')),
            ],
          ),
        ),
      ),
    );
  }
}
