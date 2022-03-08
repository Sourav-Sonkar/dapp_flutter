import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;

  late Web3Client ethClient;

//Ethereum address
  final String myAddress = "0x415B39635468051D47E8bc96A33096C139777Ae7";

//url from Infura
  final String blockchainUrl =
      "https://rinkeby.infura.io/v3/4ae062de7ed144a6bf54d2f5d4512bf0";

//store the value of alpha and beta
  var totalVotesA;
  var totalVotesB;

  @override
  void initState() {
    // TODO: implement initState
    httpClient = Client();
    ethClient = Web3Client(blockchainUrl, httpClient);
    getTotalVotes();
    super.initState();
  }

  //Construct a contract using the DeployedContract class from our web3dart
  //package, which takes in the ABI file, name of our smart contract (which
  //in our case was Voting), and the contract address and returns it from our
  //function.
  Future<DeployedContract> getContract() async {
    String abiFile = await rootBundle.loadString("asset/contract.json");
    //will retrieve from deployed contracts
    String contractAddress = "0x0C0aFE1b57ABa49a592E4734c6dfd1213e3C3A6D";
    final contract = DeployedContract(ContractAbi.fromJson(abiFile, "Voting"),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  // The next function will be used to call a function inside of our smart
  // contract:

  Future<List<dynamic>> callFunction(String name) async {
    final contract = await getContract();
    final function = contract.function(name);
    final result = await ethClient
        .call(contract: contract, function: function, params: []);
    // The line above is how we connect to our smart contract with the call
    //extension from the web3dart EthereumClient class. The result of this
    //operation is a list that the function returns:
    return result;
  }

  Future<void> getTotalVotes() async {
    List<dynamic> resultsA = await callFunction("getTotalVotesAlpha");
    List<dynamic> resultsB = await callFunction("getTotalVotesBeta");
    totalVotesA = resultsA[0];
    totalVotesB = resultsB[0];

    setState(() {});
  }

  snackBar({String? label}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label!),
            const CircularProgressIndicator(
              color: Colors.white,
            )
          ],
        ),
        duration: const Duration(days: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> vote(bool voteAlpha) async {
    try {
      snackBar(label: "Recording vote");
      //obtain private key for write operation ie from metamask
      Credentials key = EthPrivateKey.fromHex("");

      //obtain our contract from abi in json file
      final contract = await getContract();

      // extract function from json file
      final function = contract.function(
        voteAlpha ? "voteAlpha" : "voteBeta",
      );

      //send transaction using the our private key, function and contract
      await ethClient.sendTransaction(
          key,
          Transaction.callContract(
              contract: contract, function: function, parameters: []),
          chainId: 4);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      snackBar(label: "verifying vote");
      //set a 20 seconds delay to allow the transaction to be verified
      // before trying to retrieve the balance
      Future.delayed(const Duration(seconds: 20), () {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        snackBar(label: "retrieving votes");
        getTotalVotes();

        ScaffoldMessenger.of(context).clearSnackBars();
      });
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      snackBar(label: "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const CircleAvatar(
                          child: Text("A"),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Total Votes: ${totalVotesA ?? ""}",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        const CircleAvatar(
                          child: Text("B"),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text("Total Votes: ${totalVotesB ?? ""}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      vote(true);
                    },
                    child: const Text('Vote Alpha'),
                    style:
                        ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      vote(false);
                    },
                    child: const Text('Vote Beta'),
                    style:
                        ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
