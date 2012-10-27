-- Extremely simple but monstrously stupid (and slow) monadic parser
-- combinator library
module Monstupar.Core
    ( ParseError(..)
    , Monstupar, runParser
    , ok, isnot, eof, (<|>), like
    ) where

--------------------------------------------------------------------------------
-- Определения

-- Тело этого определения можно заменить на всё, что захочется
data ParseError = ParseError
                deriving (Show) -- лишь бы show был

newtype Monstupar s a = Monstupar { runParser :: [s] -> Either ParseError ([s], a) }
-- runParser :: (Monstupar s a) -> [s] -> Either ParseError ([s], a)

instance Monad (Monstupar s) where
    return a = Monstupar $ \s -> Right (s , a)
-- (>>=) ::
-- (Monstupar s) a -> (a -> (Monstupar s) b) -> (Monstupar s) b
    ma >>= f = Monstupar $ \s -> case (runParser ma s) of
        Right (s', a) -> runParser (f a) s'
        Left _        -> Left ParseError

--------------------------------------------------------------------------------
-- Примитивные парсеры.
-- Имена и сигнатуры функций менять нельзя, тела можно

-- Всё хорошо
ok :: Monstupar s ()
ok = Monstupar $ \s -> Right (s , ())

-- Не должно парситься парсером p
isnot :: Monstupar s () -> Monstupar s ()
isnot p = Monstupar $ \s -> case runParser p s of
    Left e -> Right (s , ())
    Right _ -> Left ParseError

-- Конец ввода
eof :: Monstupar s ()
eof = Monstupar $ \s -> case s of
    [] -> Right (s , ())
    _  -> Left ParseError

infixr 2 <|>
-- Сначала первый парсер, если он фейлится, то второй
(<|>) :: Monstupar s a -> Monstupar s a -> Monstupar s a
a <|> b = Monstupar $ \s -> case runParser a s of
    Left _  -> runParser b s
    a -> a

-- В голове ввода сейчас нечто, удовлетворяющее p
like :: (s -> Bool) -> Monstupar s s
like p = Monstupar $ \s -> let a = head s in
    if p $ head s
        then Right (tail s, head s)
        else Left ParseError

-- Сюда можно добавлять ещё какие-то примитивные парсеры
-- если они понадобятся

