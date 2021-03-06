{-# LANGUAGE GADTs, TypeFamilies, TemplateHaskell, QuasiQuotes, FlexibleInstances #-}
import Control.Monad.IO.Class (liftIO)
import Database.Groundhog.TH
import Database.Groundhog.Sqlite

data Shape = Circle { radius :: Double }
           | Triangle { side1 :: Double, side2 :: Double, angle :: Double } deriving Show

mkPersist defaultCodegenConfig [groundhog|
- entity: Shape
  constructors:                         # Any constructors can be adjusted in this list. The order is not important.
    - name: Triangle                    # This declaration just repeats some of the default values and can be removed.
      exprName: TriangleConstructor     # Just as default.
    - name: Circle
      fields:
        - name: radius
          exprName: CircleRadius        # The default value defined by naming style was RadiusField
|]

main = withSqliteConn ":memory:" $ runDbConn $ do
  let circle = Circle 5
  -- Both table for Circle and for Triangle of the Shape datatype are migrated.
  runMigration defaultMigrationLogger $ migrate circle
  k <- insert circle
  insert (Circle 10)
  let triangle = Triangle 3 4 (pi / 2)
  replace k triangle
  count (CircleRadius <. (11 :: Double)) >>= \c -> liftIO (putStrLn $ "Small circles: " ++ show c)
  shapes <- selectAll
  liftIO $ print (shapes :: [(AutoKey Shape, Shape)])
