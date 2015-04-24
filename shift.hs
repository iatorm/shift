import System.Environment (getArgs)
import Data.Char (isUpper)
import Control.Monad (liftM, (>=>))
import Control.Monad.Writer.Lazy (Writer, writer, tell, execWriter)
import Control.Monad.Trans.Maybe (MaybeT, runMaybeT)

type Out a = MaybeT (Writer String) a

exitWith :: String -> Out a
exitWith s = tell s >> fail ""

data Cmd = I Item
         | Apply

instance Show Cmd where
  show (I i) = "C" ++ show i
  show Apply = "!"

data Item = Blank
          | Funct {arity :: Int,
                   rule :: [Item] -> Out [Item]}

instance Show Item where
  show Blank = "?"
  show (Funct n _) = show n ++ "F"

apply :: Cmd -> [Item] -> Out [Item]
apply Apply (Funct 1 f : i : is) = liftM (++is) $ f [i]
apply Apply (Funct n f : i : is) = return $ (Funct (n-1) $ f . (i:)) : is
apply Apply (Blank : _) = exitWith $ "Error: tried to apply blank"
apply Apply [Funct n f] = f []
apply Apply [] = exitWith "Error: tried to apply empty list"
apply (I i) is = return $ i : is

parse :: String -> [Cmd]
parse = map parse' 
        . concatMap separate 
        . concatMap (words . takeWhile (not . isUpper)) 
        . lines
  where separate "" = []
        separate s@(c:str) = 
          if c `elem` symbols
          then [c] : separate str
          else wd : separate rest
            where (wd,rest) = span (not . (`elem` symbols)) s
        symbols = "!?+>/$.@"
        parse' "!" = Apply
        parse' "?" = I Blank
        parse' "clone" = clone
        parse' "+" = clone
        parse' "shift" = shift
        parse' ">" = shift
        parse' "fork" = fork
        parse' "/" = fork
        parse' "call" = call
        parse' "$" = call
        parse' "chain" = chain
        parse' "." = chain
        parse' "say" = say
        parse' "@" = say

interpret :: String -> String
interpret = execWriter . runMaybeT . ($ []) . foldr1 (>=>) . map apply . parse

main :: IO ()
main = do
  [file] <- getArgs
  prog <- readFile file
  putStrLn $ interpret prog

clone = let f (i : is) = return $ i:i:is
            f [] = exitWith "Error: tried to apply clone to empty list"
        in I $ Funct 1 f

shift = let f (Funct n g : is) = return $ Funct (n+1) h : is
              where h (x:xs) = liftM (x:) $ g xs
                    h [] = exitWith $ "Error: tried to apply shifted " ++ show (n+1) ++ "-ary function to empty list"
            f is@(Blank:_) = exitWith "Error: tried to apply shift to blank"
            f [] = exitWith "Error: tried to apply shift to empty list"
        in I $ Funct 1 f

fork = let f (Blank : i : _ : is) = return $ i : is
           f (_ : _ : is) = return is
           f is = exitWith $ "Error: tried to apply fork to " ++ show (length is) ++ "-element list"
       in I $ Funct 3 f

call = I $ Funct 2 $ apply Apply

chain = let f (Funct m h : Funct n g : is) =
              return $ (Funct m $ h >=> \js -> liftM (++ drop n js) $ g (take n js)):is
            f (_ : _ : is) = exitWith "Error: tried to apply chain to blank"
            f is = exitWith $ "Error: tried to apply fork to " ++ show (length is) ++ "-element list"
        in I $ Funct 2 f

say = let f is@(Blank : _) = writer (is,"0")
          f is@(_ : _) = writer (is,"1")
          f is = exitWith "Error: tried to apply say to empty list"
      in I $ Funct 1 f