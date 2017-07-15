{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

module Network.DigitalOcean where

-----------------------------------------------------------------
import           Data.Maybe                (fromJust, isNothing)
import           Data.Monoid               ((<>))
import           Control.Lens
import           Data.List                 (intercalate)
import           Data.Proxy
import           Control.Monad
import           Control.Monad.Reader
import           Control.Monad.Except
-----------------------------------------------------------------
import           Network.DigitalOcean.Types
import           Network.DigitalOcean.Http
import           Network.DigitalOcean.Utils.Pagination
-----------------------------------------------------------------

runDo' :: Client -> DO a -> IO (Either String a)
runDo' client do' = runExceptT $ runReaderT (runDO do') client

getAccounts :: DO Account
getAccounts = get (Proxy :: Proxy Account) "/account" Nothing

getActions :: Maybe PaginationConfig -> DO Int
getActions = \case
  Just config -> do
    let queryParams = paginationQueryParams config
    pagination <- get (Proxy :: Proxy (PaginationState Action)) "/actions" (Just queryParams)
    length . curr <$> paginateUntil config pagination (\url -> get' (Proxy :: Proxy (PaginationState Action)) url Nothing)
  Nothing ->
    length . curr <$> get (Proxy :: Proxy (PaginationState Action)) "/actions" Nothing
