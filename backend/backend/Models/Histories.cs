using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace backend.Models
{
    public class Histories
    {
        [BsonId]
        [BsonRequired]
        public string Id => $"{UserId}_{TrackId}";

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string TrackId { get; set; }

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string UserId { get; set; }

        [BsonElement("last_play")]
        public DateTime? LastPlay { get; set; }
    }
}
