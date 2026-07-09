import 'package:flutter/material.dart';

class StickerListing {
  final String id;
  final String sellerName;
  final String neighborhood;
  final double distanceKm;
  final String team;
  final String stickerCode;
  final String stickerName;
  final int quantity;
  final List<String> wants;
  final String meetingSpot;
  final Color color;
  final bool verified;

  const StickerListing({
    required this.id,
    required this.sellerName,
    required this.neighborhood,
    required this.distanceKm,
    required this.team,
    required this.stickerCode,
    required this.stickerName,
    required this.quantity,
    required this.wants,
    required this.meetingSpot,
    required this.color,
    this.verified = false,
  });
}

class StickerProfile {
  final String name;
  final String city;
  final String neighborhood;
  final int completed;
  final int missing;
  final int duplicates;
  final double trustScore;

  const StickerProfile({
    required this.name,
    required this.city,
    required this.neighborhood,
    required this.completed,
    required this.missing,
    required this.duplicates,
    required this.trustScore,
  });
}

const StickerProfile demoStickerProfile = StickerProfile(
  name: 'Vitor Almeida',
  city: 'Sao Paulo',
  neighborhood: 'Vila Madalena',
  completed: 418,
  missing: 220,
  duplicates: 37,
  trustScore: 4.8,
);

const List<StickerListing> demoStickerListings = [
  StickerListing(
    id: '1',
    sellerName: 'Camila R.',
    neighborhood: 'Pinheiros',
    distanceKm: 1.2,
    team: 'Brasil',
    stickerCode: 'BRA 12',
    stickerName: 'Atacante titular',
    quantity: 3,
    wants: ['ARG 08', 'FRA 19', 'ESP 02'],
    meetingSpot: 'Metro Faria Lima',
    color: Color(0xFF1B8A5A),
    verified: true,
  ),
  StickerListing(
    id: '2',
    sellerName: 'Rafael M.',
    neighborhood: 'Perdizes',
    distanceKm: 3.8,
    team: 'Argentina',
    stickerCode: 'ARG 08',
    stickerName: 'Craque da selecao',
    quantity: 2,
    wants: ['BRA 12', 'URU 04'],
    meetingSpot: 'Shopping Bourbon',
    color: Color(0xFF2086C9),
  ),
  StickerListing(
    id: '3',
    sellerName: 'Luana P.',
    neighborhood: 'Aclimacao',
    distanceKm: 5.4,
    team: 'Franca',
    stickerCode: 'FRA 19',
    stickerName: 'Meio-campista',
    quantity: 4,
    wants: ['POR 07', 'BRA 03', 'JPN 11'],
    meetingSpot: 'Parque da Aclimacao',
    color: Color(0xFF3156A3),
    verified: true,
  ),
  StickerListing(
    id: '4',
    sellerName: 'Nicolas T.',
    neighborhood: 'Moema',
    distanceKm: 7.1,
    team: 'Portugal',
    stickerCode: 'POR 07',
    stickerName: 'Capitao',
    quantity: 1,
    wants: ['FRA 19', 'GER 10'],
    meetingSpot: 'Metro Eucaliptos',
    color: Color(0xFFB12A34),
  ),
];

const List<StickerListing> demoMyDuplicates = [
  StickerListing(
    id: 'd1',
    sellerName: 'Voce',
    neighborhood: 'Vila Madalena',
    distanceKm: 0,
    team: 'Brasil',
    stickerCode: 'BRA 03',
    stickerName: 'Escudo oficial',
    quantity: 5,
    wants: ['ARG 08', 'FRA 19'],
    meetingSpot: 'A combinar',
    color: Color(0xFF1B8A5A),
  ),
  StickerListing(
    id: 'd2',
    sellerName: 'Voce',
    neighborhood: 'Vila Madalena',
    distanceKm: 0,
    team: 'Japao',
    stickerCode: 'JPN 11',
    stickerName: 'Goleiro',
    quantity: 3,
    wants: ['POR 07', 'ESP 02'],
    meetingSpot: 'A combinar',
    color: Color(0xFFD53F45),
  ),
  StickerListing(
    id: 'd3',
    sellerName: 'Voce',
    neighborhood: 'Vila Madalena',
    distanceKm: 0,
    team: 'Uruguai',
    stickerCode: 'URU 04',
    stickerName: 'Zagueiro',
    quantity: 2,
    wants: ['GER 10', 'BRA 12'],
    meetingSpot: 'A combinar',
    color: Color(0xFF5EA9DD),
  ),
];
