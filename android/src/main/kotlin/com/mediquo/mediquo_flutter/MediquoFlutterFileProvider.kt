package com.mediquo.mediquo_flutter

import androidx.core.content.FileProvider

/**
 * FileProvider registered on the `${applicationId}` authority that the MediQuo
 * SDK uses to share camera captures, attachments and downloaded PDFs.
 *
 * A dedicated subclass keeps the manifest entry from merging with any plain
 * [FileProvider] a host app or another library declares.
 */
class MediquoFlutterFileProvider : FileProvider(R.xml.mediquo_flutter_file_paths)
