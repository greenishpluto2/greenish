import Link from "next/link";
import type { NextPage } from "next";
import { BugAntIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { MetaHeader } from "~~/components/MetaHeader";
import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';

const Home: NextPage = () => {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [bets, setBets] = useState([]);

  useEffect(() => {
      if (window.ethereum) {
          const provider = new ethers.providers.Web3Provider(window.ethereum);
          const signer = provider.getSigner();
          const contract = new ethers.Contract(contractAddress, contractABI, signer);
          
          setProvider(provider);
          setSigner(signer);
          setContract(contract);

          // Load bets from the contract
          loadBets();
      }
  }, []);

  const loadBets = async () => {
      setBets(bets);
  };

  const placeBet = async (betId, amount) => {
      await contract.placeBet(betId, { value: ethers.utils.parseEther(amount) });
  };

  const withdrawWinnings = async (betId) => {
      await contract.withdraw(betId);
  };

  const createSocialPool = async (description, isPrivate) => {
      await contract.openBet(newBetId, description, isPrivate);
  };
  return (
    <>
      <MetaHeader />
      <div className="min-h-screen flex flex-col justify-center items-center">
    <h1 className="text-4xl font-bold text-gray-800 mb-8">Betting App</h1>

    <div className="space-y-4">
        <button className="px-6 py-2 rounded bg-blue-500 text-white font-semibold hover:bg-blue-600">Bet on Pool A</button>
        <button className="px-6 py-2 rounded bg-green-500 text-white font-semibold hover:bg-green-600">Bet on Pool B</button>
        <button className="px-6 py-2 rounded bg-red-500 text-white font-semibold hover:bg-red-600">Bet on Pool C</button>
    </div>

    <div className="mt-8 space-y-4">
        <button className="px-6 py-2 rounded bg-yellow-500 text-white font-semibold hover:bg-yellow-600">Withdraw Bets</button>
        <button className="px-6 py-2 rounded bg-purple-500 text-white font-semibold hover:bg-purple-600">Create Social Pool</button>
    </div>
</div>

<div>
            {bets.map(bet => (
                <div key={bet.id}>
                    <h2>{bet.description}</h2>
                    <button onClick={() => placeBet(bet.id, "0.1")}>Place Bet</button>
                    <button onClick={() => withdrawWinnings(bet.id)}>Withdraw Winnings</button>
                </div>
            ))}
            <button onClick={() => createSocialPool("Example Pool", true)}>Create Social Pool</button>
        </div>

    </>
  );
};

export default Home;
