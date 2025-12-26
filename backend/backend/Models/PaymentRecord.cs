using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;

namespace backend.Models
{
    public class PaymentRecord
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("userId")]
        public string UserId { get; set; }

        [BsonElement("orderId")]
        public string OrderId { get; set; }

        [BsonElement("amount")]
        public decimal Amount { get; set; }

        [BsonElement("paymentTime")]
        public DateTime PaymentTime { get; set; } 


        [BsonElement("tier")]
        public string Tier { get; set; }
    }
}
