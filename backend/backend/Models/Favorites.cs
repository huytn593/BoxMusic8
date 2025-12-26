using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace backend.Models
{
    public class Favorites
    {
        [BsonId]
        [BsonRequired]
        public string Id => $"{UserId}_{TrackId}";  // Composite key

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string TrackId { get; set; }

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string UserId { get; set; }
    }
}
