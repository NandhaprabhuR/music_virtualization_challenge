class ApiConstants {
  ApiConstants._();

  // Deezer API
  static const String deezerBaseUrl = 'https://api.deezer.com';
  static const String searchTracksEndpoint = '/search/track';
  static const String trackDetailEndpoint = '/track';

  // LRCLIB API
  static const String lrclibBaseUrl = 'https://lrclib.net';
  static const String lyricsCachedEndpoint = '/api/get-cached';
  static const String lyricsSearchEndpoint = '/api/search';

  // Paging
  static const int pageSize = 100;

  // Playlist-based loading (works globally, unlike /search which is geo-blocked)
  // We cycle through these playlists, paginating each one, to build the library.
  static const int playlistPageSize = 100;

  static const List<String> playlistIds = [
    '3155776842',
    '1313621735',
    '4403076402',
    '1677006641',
    '53362031',
    '1282495565',
    '1111141961',
    '1214944503',
    '3338949242',
    '1130102843',
    '11335739484',
    '10952747602',
    '8931919502',
    '11906567121',
    '11225266244',
    '10778288202',
    '10775127922',
    '1996494362',
    '6297682184',
    '5765498804',
    '1914338722',
    '3076498882',
    '7481945484',
    '2098157264',
    '730296295',
    '1363560485',
    '2074988442',
    '705886615',
    '2528718864',
    '1718901742',
    '4523380882',
    '4738197062',
    '4815498322',
    '1362527555',
    '1478615845',
    '8696785822',
    '5453878764',
    '9072720862',
    '6855498324',
  ];

  // Query characters used to fetch 50k+ tracks across multiple queries
  // (fallback if search endpoint works in the user's region)
  static const List<String> searchQueries = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    // Tamil songs
    'Anirudh',
    'AR Rahman Tamil',
    'Vijay Tamil song',
    'Dhanush Tamil',
    'Yuvan Shankar Raja',
    'Sid Sriram Tamil',
    'Ilaiyaraaja',
    'Harris Jayaraj',
    'Imman Tamil',
    'GV Prakash',
    // Hindi songs
    'Arijit Singh',
    'Pritam Hindi',
    'Atif Aslam',
    'Shreya Ghoshal',
    'Neha Kakkar',
    'Honey Singh',
    'Lata Mangeshkar',
    'Kishore Kumar',
    'AR Rahman Hindi',
    'Jubin Nautiyal',
  ];

  // Max pages per query character to avoid infinite fetching
  static const int maxPagesPerQuery = 56;
}
