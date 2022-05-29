- **Covariance**: Output-variance or read-variance  
   Dog is Animal, therefore `IEnumerable<Dog>` is `IEnumerable<Animal>`  
   `.get()` returns a Dog/Animal

- **Contravariance**: Input-variance or write-variance  
  Cat is Animal, therefore `Feeder<Animal>` is `Feeder<Cat>`   
  `.feed(me: Cat/Animal)` takes an input


https://www.youtube.com/watch?v=LoeEstgMXQs
