module BeetCoin.Network.Process where

import BeetCoin.Network.Types
  ( BeetCoinProcess (..), BcNetworkAddress (..), Message (..), Letter (..)
  , ProcessConfig (..), ProcessState (..), BcNodeId (..), PeerSet (..)
  )
import BeetCoin.Network.Utils (mkBcNetworkAddress)

import Control.Concurrent (threadDelay)
import Control.Distributed.Process
  ( ProcessId (..), Process (..), NodeId (..), send, register, say
  , getSelfPid, receiveWait, nsendRemote, match
  )
import Control.Distributed.Process.Node (LocalNode, newLocalNode, initRemoteTable, runProcess)
import Control.Monad (forever)
import Control.Monad.RWS (listen, asks, gets, runRWST)
import Control.Monad.Trans (MonadIO, lift, liftIO)
import qualified Data.Set as S (empty)
import Network.Transport.TCP (createTransport, defaultTCPParameters)

newProcessState :: ProcessState
newProcessState = ProcessState (PeerSet S.empty)

logMessage :: String -> Process ()
logMessage msg = say $ "handling " ++ msg

createNode :: String -> String -> IO (LocalNode)
createNode host port = do
  Right transport <- createTransport host port defaultTCPParameters
  newLocalNode transport initRemoteTable >>= return

bcProcess1 :: BeetCoinProcess Process ()
bcProcess1 = do
  let peer_address = mkBcNetworkAddress "127.0.0.1" "4000" "beetcoin-process-4000"
  sendLetter peer_address HelloMessage
  lift $ say "sent hello"
  action <- lift $ receiveWait [match (letterHandler)]
  action

bcProcess2 :: BeetCoinProcess Process ()
bcProcess2 = do
  action <- lift $ receiveWait [match (letterHandler)]
  action


letterHandler :: Letter -> Process (BeetCoinProcess Process ())
letterHandler letter =
  case _msg letter of
    HelloMessage      -> return $ handleHelloMessage (_sender letter)
    PeerMessage peers -> return $ handlePeerMessage (_sender letter) peers 

handleHelloMessage :: BcNetworkAddress -> BeetCoinProcess Process ()
handleHelloMessage peer_address = do
  peers <- gets _myPeers
  lift $ say "got hello\n"
  sendLetter peer_address (PeerMessage peers)

handlePeerMessage :: BcNetworkAddress -> PeerSet -> BeetCoinProcess Process ()
handlePeerMessage sender_address peers = do
  lift . say  $ "got peers: " ++ (show peers)


sendLetter :: BcNetworkAddress -> Message -> BeetCoinProcess Process ()
sendLetter peer_address msg = do
  self_address <- asks (_selfAddress)
  lift $ nsendRemote (_unBcNodeId . _nodeId $ peer_address)
                     (_pName peer_address)
                     (Letter self_address peer_address msg)


process1 = do
  node <- createNode "127.0.0.1" "3939"
  runProcess node $ do
    pid <- getSelfPid
    register "beetcoin-process-3939" pid
    say "beetcoin-process-3939 spawned!"
    runRWST (_unBeetCoinProcess bcProcess1) (ProcessConfig (mkBcNetworkAddress "127.0.0.1" "3939" "beetcoin-process-3939")) newProcessState
    return ()

process2 = do
  node <- createNode "127.0.0.1" "4000"
  runProcess node $ do
    pid <- getSelfPid
    register "beetcoin-process-4000" pid
    say "beetcoin-process-4000 spawned!"
    runRWST (_unBeetCoinProcess bcProcess2) (ProcessConfig (mkBcNetworkAddress "127.0.0.1" "4000" "beetcoin-process-4000")) newProcessState
    return ()
