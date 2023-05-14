#include <iostream>
#include <fstream>
#include <random>
#include <string>
#include <unordered_set>
#include <vector>
#include <cassert>

// Using (void) to silence unused warnings.
#define assertm(exp, msg) assert(((void)msg, exp))

static constexpr std::string_view kFolderPath = "../gen_inserts_data/";

template <typename... Args>
std::string FormInsertHelper(std::string&& accum, std::string&& arg1, Args&&... args) {
  accum += arg1 + ",";
  return FormInsertHelper(std::move(accum), std::move(args)...);
}

template <>
std::string FormInsertHelper<>(std::string&& accum, std::string&& arg1) {
  std::string res = std::move(accum);
  res += arg1 + ")";
  return std::move(res);
}

template <typename... Args>
std::string FormInsert(Args&&... args) {
  std::string accum = "(";
  return FormInsertHelper(std::move(accum), std::move(args)...);
}

////////////////////////////////////////////////////////////////////////////////

struct NameData {
  static constexpr std::string_view kNamesFilename = "foreign_names.txt";
  static constexpr size_t kNamesCount = 25000;

  NameData() {
    if (addr_ == nullptr) {
      addr_ = this;
      names_data.resize(kNamesCount);
      std::ifstream data_stream(std::string(kFolderPath) + std::string(kNamesFilename));
      std::getline(data_stream, names_data[0]); // read heading.
      for (size_t i = 0; i < kNamesCount; ++i) {
        std::getline(data_stream, names_data[i]);
      }
    }
  }

  static std::vector<std::string> names_data;

 private:
  NameData* addr_ = nullptr;
};

std::vector<std::string> NameData::names_data;

class Generator {
 public:
  struct PersonInfo {
    std::string name;
    std::string gender;
    std::string email;
  };

  struct Valid {
      std::string from;
      std::string to;
  };

  Generator()
      : mt_gen_(std::random_device{}()),
        names_data_(NameData::names_data) {}

  std::string get_id() {
    size_t res = random_num(kNamesCount);
    while (!id_set_.insert(res).second) {
      res = random_num(kNamesCount);
    }
    id_vec.push_back(res);
    return std::to_string(res);
  }

  std::string get_phone() {
    std::string res = "'+7";
    for (size_t i = 0; i < 10; ++i) {
      res += std::to_string(mt_gen_() % 10);
    }
    res += "'";
    return res;
  }

  std::string get_birthday_date(bool no_null) {
    std::string res = get_date(kMinPersonAge, kMaxPersonAge, no_null);
    return res;
  }

  std::string get_order_date(bool no_null) {
    std::string res = get_date(kMinOrderOffAge, kMaxOrderOffAge, no_null);
    return res;
  }

  std::string get_category_date() {
      std::string res = get_date(3, 5, true);
      return res;
  }

  Valid get_valid() {
      return {get_date(1, 2, true), "'9999-12-31'"};
  }

  std::string get_money(size_t min_price, size_t max_price) {
    size_t val = mt_gen_() % (max_price - min_price) + min_price;
    size_t copy = val;
    size_t order = 0;
    while (copy != 0) {
        copy /= 10;
        ++order;
    }
    order = std::min(order - 2, size_t(3));
    size_t ten = 1;
    for (size_t i = 0; i < order; ++i) {
        ten *= 10;
    }
    val = (val / ten) * ten;
    std::string res = std::to_string(val) + ".00";
    return res;
  }

  std::string get_payment_way() {
    std::string res;
    size_t ind = random_num(100);
    if (ind < 75) {
      res = "'card'";
    } else if (ind < 95) {
      res = "'cash'";
    } else {
      res = "'online'";
    }
    return res;
  }

  PersonInfo get_person_info(bool no_null = false) {
    size_t str_ind = random_num(kNamesCount);
    std::string name = std::move(get_data(str_ind, Name));


    std::string gender;
    if (!no_null && mt_gen_() % 10 == 0) {
      gender = "'N'";
    } else {
      gender = std::move(get_data(str_ind, Gender));
      if (gender == "Male") {
        gender = "'M'";
      } else if (gender == "Female") {
        gender = "'F'";
      } else {
        gender = "'N'";
      }
    }

    std::string email;
    if (!no_null && mt_gen_() % 10 == 0) {
      email = "'N'";
    } else {
      email = "'" + name + "@gmail.com'";
    }

    name = "'" + std::move(name) + "'";

    return {std::move(name), std::move(gender), std::move(email)};
  }

  size_t random_num(size_t ind) {
    return mt_gen_() % ind;
  }

  std::vector<size_t> id_vec;

 private:
  enum NamesColumns {
    Id = 0,
    Name,
    Meaning,
    Gender,
    Origin,

  };

  static constexpr size_t kNamesCount = NameData::kNamesCount;
  static constexpr size_t kCurAge = 2023;
  static constexpr size_t kMaxPersonAge = 55;
  static constexpr size_t kMinPersonAge = 16;
  static constexpr size_t kMaxOrderOffAge = 5;
  static constexpr size_t kMinOrderOffAge = 0;
  static constexpr size_t kMonthCount = 12;
  static constexpr size_t kDaysInMonth = 28;

  std::mt19937_64 mt_gen_;
  std::vector<std::string>& names_data_;
  std::unordered_set<size_t> id_set_;

  std::string get_data(size_t str_ind, NamesColumns column) {
    std::string& str = names_data_[str_ind];
    size_t start_pos = 0;

    size_t to_skip = static_cast<size_t>(column);
    while (to_skip > 0) {
      start_pos = str.find(';', start_pos + 1);
      assertm(start_pos != std::string::npos, "get_data: start_pos == npos");
      --to_skip;
    }

    size_t finish_pos = str.find(';', start_pos + 1);
    assertm(finish_pos != std::string::npos, "get_data: finish_pos == npos");

    return std::move(str.substr(start_pos + 1, finish_pos - start_pos - 1));
  }

  std::string get_date(size_t min_age_off, size_t max_age_off, bool no_null) {
    std::string res;
    if (!no_null && mt_gen_() % 10 == 0) {
      res = "'9999-12-31'";
      return res;
    }

    size_t age = mt_gen_() % (max_age_off - min_age_off) + min_age_off;
    res += "'" + std::to_string(kCurAge - age);

    size_t num = mt_gen_() % kMonthCount + 1;
    if (num < 10) {
      res += "-0" + std::to_string(num);
    } else {
      res += "-" + std::to_string(num);
    }

    num = mt_gen_() % kDaysInMonth + 1;
    if (num < 10) {
      res += "-0" + std::to_string(num);
    } else {
      res += "-" + std::to_string(num);
    }

    res += "'";
    return res;
  }
};

////////////////////////////////////////////////////////////////////////////////

std::string GenerateClient(Generator& gen) {
  Generator::PersonInfo prs = std::move(gen.get_person_info());

  std::string res;
  res = std::move(FormInsert(std::move(gen.get_id()),
                             std::move(prs.name),
                             std::move(prs.gender),
                             std::move(gen.get_birthday_date(false)),
                             std::move(gen.get_phone()),
                             std::move(prs.email)));
  return std::move(res);
}

void GenerateClientData(Generator& gen, size_t count) {
  std::ofstream out(std::string(kFolderPath) + "client.txt",
                    std::ios_base::out | std::ios_base::trunc);
  out << "-- " << count << " inserts\n";
  std::string heading = "insert into osh.client\n"
                        "    (client_id, name, gender, birthday_dt, phone, email)\n"
                        "values\n";
  out << heading;

  for (size_t i = 0; i < count - 1; ++i) {
    out << GenerateClient(gen) << ",\n";
  }

  out << GenerateClient(gen) << ";\n";
}

////////////////////////////////////////////////////////////////////////////////

std::string GenerateCourier(Generator& gen) {
  Generator::PersonInfo prs = std::move(gen.get_person_info(true));

  std::string res;
  res = std::move(FormInsert(std::move(gen.get_id()),
                             std::move(prs.name),
                             std::move(prs.gender),
                             std::move(gen.get_birthday_date(true)),
                             std::move(gen.get_phone()),
                             std::move(prs.email)));
  return std::move(res);
}

void GenerateCourierData(Generator& gen, size_t count) {
  std::ofstream out(std::string(kFolderPath) + "courier.txt",
                    std::ios_base::out | std::ios_base::trunc);
  out << "-- " << count << " inserts\n";
  std::string heading = "insert into osh.courier\n"
                        "    (courier_id, name, gender, birthday_dt, phone, email)\n"
                        "values\n";
  out << heading;

  for (size_t i = 0; i < count - 1; ++i) {
    out << GenerateCourier(gen) << ",\n";
  }

  out << GenerateCourier(gen) << ";\n";
}

////////////////////////////////////////////////////////////////////////////////

std::string GenerateOrder(Generator& gen, Generator& client_gen) {
  Generator::PersonInfo prs = std::move(gen.get_person_info(true));

  size_t ind = gen.random_num(client_gen.id_vec.size());
  std::string clt_id = std::to_string(client_gen.id_vec[ind]);

  std::string res;
  res = std::move(FormInsert(std::move(gen.get_id()),
                             std::move(clt_id),
                             std::move(gen.get_order_date(true)),
                             std::move(gen.get_payment_way())));
  return std::move(res);
}

void GenerateOrderData(Generator& gen, Generator& client_gen, size_t count) {
  std::ofstream out(std::string(kFolderPath) + "order.txt",
                    std::ios_base::out | std::ios_base::trunc);
  out << "-- " << count << " inserts\n";
  std::string heading = "insert into osh.order\n"
                        "    (order_id, client_id, order_dt, payment_way)\n"
                        "values\n";
  out << heading;

  for (size_t i = 0; i < count - 1; ++i) {
    out << GenerateOrder(gen, client_gen) << ",\n";
  }

  out << GenerateOrder(gen, client_gen) << ";\n";
}

////////////////////////////////////////////////////////////////////////////////

std::string GenerateOrderDelivery(Generator& gen, Generator& order_gen, Generator& courier_gen) {
  size_t vec_ind;

  static size_t key = 0;
  std::string order_id = std::to_string(order_gen.id_vec[key]);
  ++key;

  vec_ind = gen.random_num(courier_gen.id_vec.size());
  std::string courier_id = std::to_string(courier_gen.id_vec[vec_ind]);

  std::string res;
  res = std::move(FormInsert(std::move(order_id),
                             std::move(courier_id)));
  return std::move(res);
}

void GenerateOrderDeliveryData(Generator& gen, Generator& order_gen, Generator& courier_gen) {
  std::ofstream out(std::string(kFolderPath) + "order_delivery.txt",
                    std::ios_base::out | std::ios_base::trunc);
  size_t count = order_gen.id_vec.size();

  out << "-- " << count << " inserts\n";
  std::string heading = "insert into osh.order_delivery\n"
                        "    (order_id, courier_id)\n"
                        "values\n";
  out << heading;

  for (size_t i = 0; i < count - 1; ++i) {
    out << GenerateOrderDelivery(gen, order_gen, courier_gen) << ",\n";
  }

  out << GenerateOrderDelivery(gen, order_gen, courier_gen) << ";\n";
}

////////////////////////////////////////////////////////////////////////////////

std::vector<std::pair<std::string, std::string>> mans_vec {{"Promobot", "Russia"},
                                                           {"Regatop", "Russia"},
                                                           {"Veon", "Russia"},
                                                           {"Megaless", "Belarus"},
                                                           {"Shevel", "Belarus"},
                                                           {"Tesavorics", "Poland"}};

std::string GenerateManufacturer(Generator& gen) {
    Generator::PersonInfo prs = std::move(gen.get_person_info());

    static size_t key = 0;
    std::pair<std::string, std::string> cur = mans_vec[key];
    ++key;

    std::string res;
    res = std::move(FormInsert(std::move("'" + cur.first + "'"),
                               std::move(gen.get_phone()),
                               std::move("'" + cur.first + "@gmail.com'"),
                               std::move("'" + cur.second + "'")));
    return std::move(res);
}

void GenerateManufacturerData(Generator& gen) {
    std::ofstream out(std::string(kFolderPath) + "manufacturer.txt",
                      std::ios_base::out | std::ios_base::trunc);
    size_t count = mans_vec.size();
    out << "-- " << count << " inserts\n";
    std::string heading = "insert into osh.manufacturer\n"
                          "    (manufacturer_nm, phone, email, country)\n"
                          "values\n";
    out << heading;

    for (size_t i = 0; i < count - 1; ++i) {
        out << GenerateManufacturer(gen) << ",\n";
    }

    out << GenerateManufacturer(gen) << ";\n";
}

////////////////////////////////////////////////////////////////////////////////

std::vector<std::string> category_vec{"phones", "laptops", "electronics", "appliances", "construction", "food"};

std::string GenerateCategory(Generator& gen) {
    Generator::PersonInfo prs = std::move(gen.get_person_info());

    static size_t key = 0;
    std::string name = category_vec[key];
    ++key;

    std::string res;
    res = std::move(FormInsert(std::move("'" + name + "'"),
                               std::move(gen.get_category_date())));
    return std::move(res);
}

void GenerateCategoryData(Generator& gen) {
    std::ofstream out(std::string(kFolderPath) + "category.txt",
                      std::ios_base::out | std::ios_base::trunc);
    size_t count = category_vec.size();
    out << "-- " << count << " inserts\n";
    std::string heading = "insert into osh.category\n"
                          "    (category_nm, creation_dt)\n"
                          "values\n";
    out << heading;

    for (size_t i = 0; i < count - 1; ++i) {
        out << GenerateCategory(gen) << ",\n";
    }

    out << GenerateCategory(gen) << ";\n";
}

////////////////////////////////////////////////////////////////////////////////

std::string GenerateProduct(Generator& gen) {
    Generator::PersonInfo prs = std::move(gen.get_person_info(true));

    Generator::Valid valid = gen.get_valid();

    std::string man_name = "'" + mans_vec[gen.random_num(mans_vec.size())].first + "'";

    std::string res;
    res = std::move(FormInsert(std::move(gen.get_id()),
                               std::move("'###name###'"),
                               std::move("'" + category_vec[gen.random_num(category_vec.size())] + "'"),
                               std::move(gen.get_money(1000, 120000)),
                               std::move(man_name),
                               std::move(std::to_string(gen.random_num(5) + 1)),
                               std::move(valid.from),
                               std::move(valid.to)));
    return std::move(res);
}

void GenerateProductData(Generator& gen, size_t count) {
    std::ofstream out(std::string(kFolderPath) + "product.txt",
                      std::ios_base::out | std::ios_base::trunc);
    out << "-- " << count << " inserts\n";
    std::string heading = "insert into osh.product\n"
                          "    (product_id, name, category_nm, price, manufacturer_nm, rating, valid_from_dt, valid_to_dt)\n"
                          "values\n";
    out << heading;

    for (size_t i = 0; i < count - 1; ++i) {
        out << GenerateProduct(gen) << ",\n";
    }

    out << GenerateProduct(gen) << ";\n";
}

////////////////////////////////////////////////////////////////////////////////

std::string GenerateProductInOrder(Generator& gen, Generator& order_gen, Generator& product_gen) {
    size_t vec_ind;

    static size_t key = 0;
    std::string order_id = std::to_string(order_gen.id_vec[key]);
    ++key;

    vec_ind = gen.random_num(product_gen.id_vec.size());
    std::string product_id = std::to_string(product_gen.id_vec[vec_ind]);

    std::string res;
    res = std::move(FormInsert(std::move(order_id),
                               std::move(product_id),
                               std::to_string(gen.random_num(3) + 1)));
    return std::move(res);
}

void GenerateProductInOrderData(Generator& gen, Generator& order_gen, Generator& product_gen) {
    std::ofstream out(std::string(kFolderPath) + "product_in_order.txt",
                      std::ios_base::out | std::ios_base::trunc);
    size_t count = order_gen.id_vec.size();

    out << "-- " << count << " inserts\n";
    std::string heading = "insert into osh.product_in_order\n"
                          "    (order_id, product_id, count)\n"
                          "values\n";
    out << heading;

    for (size_t i = 0; i < count - 1; ++i) {
        out << GenerateProductInOrder(gen, order_gen, product_gen) << ",\n";
    }

    out << GenerateProductInOrder(gen, order_gen, product_gen) << ";\n";
}


int main() {
  NameData data;

  Generator client_gen;
  GenerateClientData(client_gen, 60);

  Generator courier_gen;
  GenerateCourierData(courier_gen, 15);

  Generator order_gen;
  GenerateOrderData(order_gen, client_gen, 300);

  Generator order_delivery_gen;
  GenerateOrderDeliveryData(order_delivery_gen, order_gen, courier_gen);

  Generator manufacturer_gen;
  GenerateManufacturerData(manufacturer_gen);

  Generator category_gen;
  GenerateCategoryData(category_gen);

  Generator product_gen;
  GenerateProductData(product_gen, 30);

  Generator product_in_order_gen;
  GenerateProductInOrderData(product_in_order_gen, order_gen, product_gen);
}
