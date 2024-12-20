class DownloadItems {
  static const apks = [
    DownloadItem(
      name: 'BIFORST ABSENSI',
      url: 'https://biforst.cbnet.my.id/api/v1/downloads',
    )
  ];
}

class DownloadItem {
  const DownloadItem({required this.name, required this.url});

  final String name;
  final String url;
}
