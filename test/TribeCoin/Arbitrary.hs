module TribeCoin.Arbitrary where

import TribeCoin.Types (TribeCoinAddress (..), PubKey (..), PubKeyHash (..), AddressChecksum (..))

import Crypto.Hash (SHA256 (..), digestFromByteString, hashWith)
import Crypto.Secp256k1 (importPubKey, secKey, derivePubKey)
import Data.ByteArray (convert)
import qualified Data.ByteString as BS (ByteString, pack, cons, take)
import Data.Either (either)
import Data.Maybe (fromJust)
import Data.Serialize (encode, decode)
import Data.Word (Word8)
import Test.Tasty.QuickCheck (Arbitrary, Gen, arbitrary, vector)

-- | Represents a random, valid public key.
newtype RandomPubKey = RandomPubKey { _unRandomPubKey :: PubKey }
  deriving (Show)

instance Arbitrary RandomPubKey where
  -- | Generate a random public key by first generating a random private key and then deriving a public
  -- key from the private key.
  arbitrary = RandomPubKey . PubKey . derivePubKey . fromJust . secKey . BS.pack <$> vector 32

-- | A valid random public key hash.
newtype RandomPubKeyHash = RandomPubKeyHash { _unRandomPubKeyHash :: PubKeyHash }
  deriving (Show)

instance Arbitrary RandomPubKeyHash where
  arbitrary = do
    bytes <- vector 20 :: Gen [Word8]
    return . RandomPubKeyHash . PubKeyHash . fromJust . digestFromByteString . BS.pack $ bytes

newtype RandomTribeCoinAddress = RandomTribeCoinAddress { _unRandomTribeCoinAddress :: TribeCoinAddress }
  deriving (Show)

instance Arbitrary RandomTribeCoinAddress where
  arbitrary = do
    pubkey_hash <- _unRandomPubKeyHash <$> arbitrary :: Gen PubKeyHash
    let bytes    = (0x00 :: Word8) `BS.cons` (encode pubkey_hash)
    let checksum = AddressChecksum . either (error "Failed to parse AddressChecksum!") (id) . decode . BS.take 4 .
                   convert . hashWith SHA256 . hashWith SHA256 $ bytes
    return . RandomTribeCoinAddress $ TribeCoinAddress pubkey_hash checksum
