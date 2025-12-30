// Create auto-embed index using private preview syntax This is the one that
// works currently with the internal images
db.movies.createSearchIndex("auto_embed_plot_index", "vectorSearch", {
  fields: [
    {
      type: "text",
      path: "plot",
      model: "voyage-3-large",
    },
  ],
});

// Create auto-embed index using public preview syntax. This is the one that
// will work with the public preview image.
db.movies.createSearchIndex("auto_embed_plot_index", "vectorSearch", {
  fields: [
    {
      type: "autoEmbedText",
      path: "plot",
      model: "voyage-3-large",
    },
  ],
});

// Creating normal vector search index
db.movies.createSearchIndex("plot_vector_index", "vectorSearch", {
  fields: [
    {
      type: "vector",
      path: "plot_embeddings",
      numDimensions: 1024,
      similarity: "cosine",
      quantization: "none",
    },
  ],
});

db.movies.insertMany([
  {
    cast: ["Cillian Murphy", "Emily Blunt", "Matt Damon"],
    director: "Christopher Nolan",
    genres: ["Biography", "Drama", "History"],
    imdb: {
      rating: 8.3,
      votes: 680000,
    },
    plot: "The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II.",
    runtime: 180,
    title: "Oppenheimer",
    year: 2023,
  },
  {
    cast: ["Andrew Garfield", "Claire Foy", "Hugh Bonneville"],
    director: "Andy Serkis",
    genres: ["Biography", "Drama", "Romance"],
    imdb: {
      rating: 7.2,
      votes: 42000,
    },
    plot: "The inspiring true love story of Robin and Diana Cavendish, an adventurous couple who refuse to give up in the face of a devastating disease.",
    runtime: 118,
    title: "Breathe",
    year: 2017,
  },
]);

db.movies.aggregate([
  {
    $vectorSearch: {
      index: "auto_embed_plot_index",
      path: "plot",
      query: { text: "movie about couples" },
      limit: 5,
      numCandidates: 5,
    },
  },
]);
