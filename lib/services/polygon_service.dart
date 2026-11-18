import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'contract_abi.dart';

class PolygonService {
  final String rpcUrl = 'ISI URL POLYGON';
  final String privateKey = 'ISI PRIVATE KEY METAMASK';

  Future<String> beliTiketOnChain({
    required BigInt totalHargaWei,
    required int jumlahTiket,
  }) async {
    try {
      final client = Web3Client(rpcUrl, http.Client());
      final credentials = EthPrivateKey.fromHex(privateKey);
      
      final contract = DeployedContract(
        ContractAbi.fromJson(contractAbi, 'TiketKeraton'),
        EthereumAddress.fromHex(contractAddress),
      );

      final function = contract.function('beliTiket');
      final gasPrice = await client.getGasPrice();
      final txHash = await client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: function,
          parameters: [BigInt.from(jumlahTiket)],
          value: EtherAmount.inWei(totalHargaWei),
          gasPrice: gasPrice,
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