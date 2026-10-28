import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'contract_abi.dart';

class PolygonService {
  final String rpcUrl = 'ISI SENDIRI YA';
  
  // GANTI DENGAN PRIVATE KEY METAMASK (Dompet Admin)
  final String privateKey = 'PRIVATE';

  Future<String> beliTiketOnChain({
    required BigInt totalHargaWei,
    required int jumlahTiket,
  }) async {
    try {
      final client = Web3Client(rpcUrl, http.Client());
      final credentials = EthPrivateKey.fromHex(privateKey);
      
      // 1. Setup Kontrak
      final contract = DeployedContract(
        ContractAbi.fromJson(contractAbi, 'TiketKeraton'),
        EthereumAddress.fromHex(contractAddress),
      );

      // 2. Ambil fungsi beliTiket
      final function = contract.function('beliTiket');

      // 3. Ambil harga gas saat ini (biar tidak error "standard")
      final gasPrice = await client.getGasPrice();

      // 4. Kirim Transaksi (pakai cara baru: Transaction.callContract)
      final txHash = await client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: function,
          parameters: [BigInt.from(jumlahTiket)], // Kirim jumlah tiket
          value: EtherAmount.inWei(totalHargaWei),
          gasPrice: gasPrice, // Pakai harga gas dari jaringan
        ),
        chainId: 80002,
        fetchChainIdFromNetworkId: false,
      );

      return txHash;
    } catch (e) {
      print("Error beli tiket on-chain: $e");
      throw Exception("Gagal mencetak tiket di blockchain: $e");
    }
  }
}