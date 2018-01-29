module BeetCoin.Network.Network where

-- import BeetCoin.Network.Types
--   ( NodeNetwork (..), NodeAddress (..), Message (..), Letter (..), NetworkState (..)
--   , SendError (..), Network (..)
--   )

-- import Control.Monad (forever)
-- import Control.Monad.RWS (RWST (..), runRWST, asks, ask)
-- import Control.Monad.State (put, get)
-- import Control.Monad.Trans (MonadIO, liftIO)
-- import qualified Data.ByteString as BS (ByteString (..))
-- import qualified Data.ByteString.Char8 as BS8 (pack)
-- import qualified Data.Map.Strict as HM (Map (..), lookup, delete, insert, empty)
-- import Network.Transport
--   ( Transport (..), EndPoint (..), Reliability (..), Connection (..), EndPointAddress (..)
--   , Event (..), TransportError (..), ConnectErrorCode (..), defaultConnectHints
--   )
-- import Data.Either (rights)
-- import Data.Serialize (Serialize, encode, decode)
-- import Network.Transport.TCP (createTransport, defaultTCPParameters)

-- mkNetwork :: Transport -> EndPoint -> Network
-- mkNetwork transport endpoint =
--   Network (NodeAddress . address $ endpoint)
--               (receive endpoint)
--               (\address -> connect endpoint (_unNodeAddress address) ReliableOrdered defaultConnectHints)
--               (send)
--               (closeEndPoint endpoint >> closeTransport transport)

-- mkNetworkState :: NetworkState
-- mkNetworkState = NetworkState HM.empty HM.empty

-- createNetwork :: MonadIO m => String -> String -> m (Network)
-- createNetwork host port = do
--   -- TODO: Handle error cases.
--   Right transport <- liftIO $ createTransport host port defaultTCPParameters
--   Right endpoint  <- liftIO $ newEndPoint transport
--   return (mkNetwork transport endpoint)

-- runNodeNetwork :: MonadIO m => NodeNetwork m a -> Network -> NetworkState -> m (a, NetworkState, ())
-- runNodeNetwork = runRWST . _unNodeNetwork

-- bindNodeNetwork :: MonadIO m => NodeNetwork m a -> String -> String -> m (a, NetworkState, ())
-- bindNodeNetwork network_action host port = do
--   network <- createNetwork host port
--   runNodeNetwork network_action network mkNetworkState

-- -- | Send some data. Connects to specified peer if not already connected.
-- -- TODO: Accumulate connection and send errors in a Writer monad.
-- sendData :: MonadIO m => NodeAddress -> [BS.ByteString] -> NodeNetwork m ()
-- sendData address bytes = do
--   network_state <- get
--   network <- ask
--   let connections = _outConns network_state
--   -- Check if we already have a connection to the peer.
--   case HM.lookup address connections of
--     -- If we aren't connected to the peer, then attempt to establish a new connection.
--     Nothing -> do
--       new_conn <- liftIO $ (_connect network) address
--       case new_conn of
--         -- Don't send anything if we can't connect to the peer.
--         Left error      -> return ()
--         -- Attempt to send the data to the peer.
--         Right new_conn' -> do
--           result <- liftIO $ (_send network) new_conn' bytes
--           case result of
--             -- Cleanup the connection if something went wrong.
--             Left error -> liftIO $ close new_conn'
--             -- Add the new connection to our connection map.
--             Right ()   -> put $ network_state { _outConns = (HM.insert address new_conn' connections) }
--     -- Attempt to send the data if we already have a connection.
--     Just conn -> do
--       result <- liftIO $ (_send network) conn bytes
--       case result of
--         -- Cleanup the connection and remove it from our connection map if something went wrong.
--         Left error -> liftIO (close conn) >> (put $ network_state { _outConns = HM.delete address connections })
--         Right ()   -> return ()

-- -- | Block until some data is received by the network.
-- -- TODO: Implement error case.
-- receiveData :: (MonadIO m, Serialize a) => NodeNetwork m [a]
-- receiveData = do
--   event <- ask >>= liftIO . _epoll
--   case event of
--     Received con_id bytes -> return . rights . fmap decode $ bytes
--     _                     -> receiveData

-- setupNetwork :: IO ()
-- setupNetwork = undefined
      