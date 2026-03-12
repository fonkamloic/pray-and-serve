import { useState, useEffect, useCallback, useRef } from "react";

const CATEGORIES = ["Family", "Health", "Work", "Spiritual Growth", "World", "Gratitude", "Church", "Personal"];
const URGENCY = ["Pressing", "Ongoing", "Background"];
const ROLES = ["Member", "Pastor", "Elder", "Deacon"];
const RECURRENCE = ["None", "Daily", "Weekly", "Monthly"];
const CARE_TAGS = ["Grieving", "New Believer", "Struggling", "Growing", "Needs Visit", "Hospital", "Homebound", "Elderly", "Unsaved"];
const NEED_TYPES = ["Meals", "Transportation", "Financial", "Home Repair", "Hospital Visit", "Encouragement", "Prayer", "Mentoring"];

const generateId = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 7);

const daysAgo = (dateStr) => {
  if (!dateStr) return Infinity;
  const diff = Date.now() - new Date(dateStr).getTime();
  return Math.floor(diff / (1000 * 60 * 60 * 24));
};

const formatDate = (dateStr) => {
  if (!dateStr) return "Never";
  return new Date(dateStr).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
};

const todayStr = () => new Date().toISOString().split("T")[0];

// Storage helpers
const loadData = async (key, fallback) => {
  try {
    const result = await window.storage.get(key);
    return result ? JSON.parse(result.value) : fallback;
  } catch { return fallback; }
};
const saveData = async (key, data) => {
  try { await window.storage.set(key, JSON.stringify(data)); } catch (e) { console.error("Save error:", e); }
};

// Icons as simple SVG components
const Icon = ({ d, size = 20, color = "currentColor", ...props }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>{typeof d === "string" ? <path d={d} /> : d}</svg>
);

const PrayIcon = (p) => <Icon {...p} d={<><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2" /><path d="M12 6v6l4 2" /></>} />;
const HeartIcon = (p) => <Icon {...p} d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />;
const PlusIcon = (p) => <Icon {...p} d={<><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></>} />;
const CheckIcon = (p) => <Icon {...p} d={<polyline points="20 6 9 17 4 12" />} />;
const BookIcon = (p) => <Icon {...p} d={<><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" /><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" /></>} />;
const UserIcon = (p) => <Icon {...p} d={<><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></>} />;
const TrashIcon = (p) => <Icon {...p} d={<><polyline points="3 6 5 6 21 6" /><path d="M19 6l-1 14H6L5 6" /><path d="M10 11v6" /><path d="M14 11v6" /><path d="M9 6V4h6v2" /></>} />;
const EditIcon = (p) => <Icon {...p} d={<><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></>} />;
const AlertIcon = (p) => <Icon {...p} d={<><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></>} />;
const PhoneIcon = (p) => <Icon {...p} d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />;
const SettingsIcon = (p) => <Icon {...p} d={<><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></>} />;
const CloseIcon = (p) => <Icon {...p} d={<><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></>} />;
const SearchIcon = (p) => <Icon {...p} d={<><circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" /></>} />;

export default function PrayAndServe() {
  const [loaded, setLoaded] = useState(false);
  const [tab, setTab] = useState("pray");
  const [role, setRole] = useState("Member");
  const [prayers, setPrayers] = useState([]);
  const [journal, setJournal] = useState([]);
  const [flock, setFlock] = useState([]);
  const [careLogs, setCareLogs] = useState([]);
  const [showModal, setShowModal] = useState(null);
  const [editItem, setEditItem] = useState(null);
  const [filter, setFilter] = useState("all");
  const [searchText, setSearchText] = useState("");
  const [showSettings, setShowSettings] = useState(false);
  const [reminderDays, setReminderDays] = useState(14);
  const [subTab, setSubTab] = useState("list");

  // Load all data on mount
  useEffect(() => {
    (async () => {
      const [r, p, j, f, c, rd] = await Promise.all([
        loadData("ps-role", "Member"),
        loadData("ps-prayers", []),
        loadData("ps-journal", []),
        loadData("ps-flock", []),
        loadData("ps-carelogs", []),
        loadData("ps-reminderdays", 14),
      ]);
      setRole(r); setPrayers(p); setJournal(j); setFlock(f); setCareLogs(c); setReminderDays(rd);
      setLoaded(true);
    })();
  }, []);

  // Save helpers
  const save = useCallback(async (key, data) => { await saveData(key, data); }, []);

  const updatePrayers = (fn) => setPrayers(prev => { const next = fn(prev); save("ps-prayers", next); return next; });
  const updateJournal = (fn) => setJournal(prev => { const next = fn(prev); save("ps-journal", next); return next; });
  const updateFlock = (fn) => setFlock(prev => { const next = fn(prev); save("ps-flock", next); return next; });
  const updateCareLogs = (fn) => setCareLogs(prev => { const next = fn(prev); save("ps-carelogs", next); return next; });

  // Prayer stats
  const totalPrayers = prayers.length;
  const answeredPrayers = prayers.filter(p => p.answered).length;
  const pressingPrayers = prayers.filter(p => p.urgency === "Pressing" && !p.answered).length;
  const overdueContacts = flock.filter(p => daysAgo(p.lastContact) > reminderDays).length;

  // Filtered prayers
  const filteredPrayers = prayers.filter(p => {
    if (filter === "answered") return p.answered;
    if (filter === "unanswered") return !p.answered;
    if (filter === "pressing") return p.urgency === "Pressing" && !p.answered;
    if (CATEGORIES.includes(filter)) return p.category === filter && !p.answered;
    return !p.answered;
  }).filter(p => !searchText || p.title.toLowerCase().includes(searchText.toLowerCase()) || (p.details || "").toLowerCase().includes(searchText.toLowerCase()));

  // Filtered flock
  const filteredFlock = flock.filter(p => !searchText || p.name.toLowerCase().includes(searchText.toLowerCase()));
  const overdueFlock = filteredFlock.filter(p => daysAgo(p.lastContact) > reminderDays);
  const recentFlock = filteredFlock.filter(p => daysAgo(p.lastContact) <= reminderDays);

  if (!loaded) return (
    <div style={styles.loadingScreen}>
      <div style={styles.loadingCross}>✝</div>
      <div style={styles.loadingText}>Pray & Serve</div>
      <div style={styles.loadingSubtext}>Preparing your sacred space...</div>
    </div>
  );

  return (
    <div style={styles.app}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;0,700;1,400&family=Source+Sans+3:wght@300;400;500;600&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        input, textarea, select, button { font-family: 'Source Sans 3', sans-serif; }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #3d3529; border-radius: 3px; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes slideUp { from { opacity: 0; transform: translateY(100%); } to { opacity: 1; transform: translateY(0); } }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
        @keyframes glow { 0%, 100% { box-shadow: 0 0 20px rgba(196,164,105,0.2); } 50% { box-shadow: 0 0 30px rgba(196,164,105,0.4); } }
      `}</style>

      {/* Header */}
      <header style={styles.header}>
        <div style={styles.headerInner}>
          <div style={styles.logoArea}>
            <span style={styles.cross}>✝</span>
            <div>
              <h1 style={styles.title}>Pray & Serve</h1>
              <p style={styles.subtitle}>Your private walk with God</p>
            </div>
          </div>
          <button style={styles.settingsBtn} onClick={() => setShowSettings(!showSettings)}>
            <SettingsIcon size={18} color="#c4a469" />
          </button>
        </div>

        {showSettings && (
          <div style={styles.settingsPanel}>
            <div style={styles.settingRow}>
              <label style={styles.settingLabel}>My Role</label>
              <select style={styles.select} value={role} onChange={e => { setRole(e.target.value); save("ps-role", e.target.value); }}>
                {ROLES.map(r => <option key={r} value={r}>{r}</option>)}
              </select>
            </div>
            <div style={styles.settingRow}>
              <label style={styles.settingLabel}>Contact Reminder (days)</label>
              <input type="number" style={{ ...styles.input, width: 80 }} value={reminderDays} onChange={e => { const v = parseInt(e.target.value) || 7; setReminderDays(v); save("ps-reminderdays", v); }} />
            </div>
          </div>
        )}

        {/* Stats Bar */}
        <div style={styles.statsBar}>
          <div style={styles.stat}>
            <span style={styles.statNum}>{totalPrayers}</span>
            <span style={styles.statLabel}>Prayers</span>
          </div>
          <div style={styles.statDivider} />
          <div style={styles.stat}>
            <span style={{ ...styles.statNum, color: "#7da87d" }}>{answeredPrayers}</span>
            <span style={styles.statLabel}>Answered</span>
          </div>
          <div style={styles.statDivider} />
          <div style={styles.stat}>
            <span style={{ ...styles.statNum, color: pressingPrayers > 0 ? "#c4785a" : "#c4a469" }}>{pressingPrayers}</span>
            <span style={styles.statLabel}>Pressing</span>
          </div>
          {role !== "Member" && <>
            <div style={styles.statDivider} />
            <div style={styles.stat}>
              <span style={{ ...styles.statNum, color: overdueContacts > 0 ? "#c4785a" : "#c4a469" }}>{overdueContacts}</span>
              <span style={styles.statLabel}>Need Contact</span>
            </div>
          </>}
        </div>

        {/* Tab Bar */}
        <div style={styles.tabBar}>
          {[
            { id: "pray", label: "Pray", icon: <HeartIcon size={16} /> },
            { id: "journal", label: "Journal", icon: <BookIcon size={16} /> },
            { id: "serve", label: "Serve", icon: <UserIcon size={16} /> },
          ].map(t => (
            <button key={t.id} style={{ ...styles.tab, ...(tab === t.id ? styles.tabActive : {}) }} onClick={() => { setTab(t.id); setSearchText(""); setFilter("all"); }}>
              {t.icon} <span style={{ marginLeft: 6 }}>{t.label}</span>
              {t.id === "serve" && overdueContacts > 0 && <span style={styles.badge}>{overdueContacts}</span>}
            </button>
          ))}
        </div>
      </header>

      {/* Main Content */}
      <main style={styles.main}>
        {/* PRAY TAB */}
        {tab === "pray" && (
          <div style={styles.fadeIn}>
            {/* Search & Filter */}
            <div style={styles.toolbar}>
              <div style={styles.searchBox}>
                <SearchIcon size={16} color="#8a7d6b" />
                <input style={styles.searchInput} placeholder="Search prayers..." value={searchText} onChange={e => setSearchText(e.target.value)} />
              </div>
              <button style={styles.addBtn} onClick={() => { setEditItem(null); setShowModal("prayer"); }}>
                <PlusIcon size={18} color="#1a1714" /> New Prayer
              </button>
            </div>

            <div style={styles.filterRow}>
              {["all", "unanswered", "pressing", "answered"].map(f => (
                <button key={f} style={{ ...styles.filterChip, ...(filter === f ? styles.filterActive : {}) }} onClick={() => setFilter(f)}>
                  {f === "all" ? "Active" : f.charAt(0).toUpperCase() + f.slice(1)}
                </button>
              ))}
              {CATEGORIES.map(c => (
                <button key={c} style={{ ...styles.filterChip, ...(filter === c ? styles.filterActive : {}) }} onClick={() => setFilter(f => f === c ? "all" : c)}>
                  {c}
                </button>
              ))}
            </div>

            {/* Prayer List */}
            {filteredPrayers.length === 0 ? (
              <div style={styles.emptyState}>
                <div style={styles.emptyIcon}>🙏</div>
                <p style={styles.emptyText}>{filter === "answered" ? "No answered prayers yet — keep trusting God." : "No prayers here yet."}</p>
                <p style={styles.emptySubtext}>Pour out your heart to Him.</p>
              </div>
            ) : (
              <div style={styles.prayerList}>
                {filteredPrayers.map((p, i) => (
                  <div key={p.id} style={{ ...styles.prayerCard, animationDelay: `${i * 0.05}s`, ...(p.answered ? styles.prayerAnswered : {}), ...(p.urgency === "Pressing" && !p.answered ? styles.prayerPressing : {}) }}>
                    <div style={styles.prayerHeader}>
                      <div style={styles.prayerMeta}>
                        <span style={{ ...styles.urgencyDot, background: p.urgency === "Pressing" ? "#c4785a" : p.urgency === "Ongoing" ? "#c4a469" : "#6b7c6b" }} />
                        <span style={styles.prayerCategory}>{p.category}</span>
                        {p.recurrence !== "None" && <span style={styles.recurrenceBadge}>↻ {p.recurrence}</span>}
                        {p.answered && <span style={styles.answeredBadge}>✓ Answered</span>}
                      </div>
                      <div style={styles.prayerActions}>
                        {!p.answered && (
                          <button style={styles.iconBtn} title="Mark Answered" onClick={() => { setEditItem(p); setShowModal("answer"); }}>
                            <CheckIcon size={16} color="#7da87d" />
                          </button>
                        )}
                        <button style={styles.iconBtn} title="Edit" onClick={() => { setEditItem(p); setShowModal("prayer"); }}>
                          <EditIcon size={14} color="#8a7d6b" />
                        </button>
                        <button style={styles.iconBtn} title="Delete" onClick={() => { if (confirm("Remove this prayer?")) updatePrayers(prev => prev.filter(x => x.id !== p.id)); }}>
                          <TrashIcon size={14} color="#8a7d6b" />
                        </button>
                      </div>
                    </div>
                    <h3 style={styles.prayerTitle}>{p.title}</h3>
                    {p.details && <p style={styles.prayerDetails}>{p.details}</p>}
                    {p.scripture && <p style={styles.prayerScripture}>📖 {p.scripture}</p>}
                    {p.answered && p.answerNote && (
                      <div style={styles.answerNote}>
                        <strong style={{ color: "#7da87d" }}>How God Answered:</strong> {p.answerNote}
                      </div>
                    )}
                    <div style={styles.prayerFooter}>
                      <span style={styles.dateText}>Created {formatDate(p.createdAt)}</span>
                      {p.answered && <span style={styles.dateText}>Answered {formatDate(p.answeredAt)}</span>}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* JOURNAL TAB */}
        {tab === "journal" && (
          <div style={styles.fadeIn}>
            <div style={styles.toolbar}>
              <h2 style={styles.sectionTitle}>Prayer Journal</h2>
              <button style={styles.addBtn} onClick={() => { setEditItem(null); setShowModal("journal"); }}>
                <PlusIcon size={18} color="#1a1714" /> New Entry
              </button>
            </div>

            {journal.length === 0 ? (
              <div style={styles.emptyState}>
                <div style={styles.emptyIcon}>📖</div>
                <p style={styles.emptyText}>Your journal is empty.</p>
                <p style={styles.emptySubtext}>Write what God is placing on your heart.</p>
              </div>
            ) : (
              <div style={styles.journalList}>
                {journal.sort((a, b) => new Date(b.date) - new Date(a.date)).map((entry, i) => (
                  <div key={entry.id} style={{ ...styles.journalCard, animationDelay: `${i * 0.05}s` }}>
                    <div style={styles.journalHeader}>
                      <span style={styles.journalDate}>{formatDate(entry.date)}</span>
                      <div style={{ display: "flex", gap: 4 }}>
                        <button style={styles.iconBtn} onClick={() => { setEditItem(entry); setShowModal("journal"); }}><EditIcon size={14} color="#8a7d6b" /></button>
                        <button style={styles.iconBtn} onClick={() => { if (confirm("Delete this entry?")) updateJournal(prev => prev.filter(x => x.id !== entry.id)); }}><TrashIcon size={14} color="#8a7d6b" /></button>
                      </div>
                    </div>
                    {entry.title && <h3 style={styles.journalTitle}>{entry.title}</h3>}
                    <p style={styles.journalBody}>{entry.body}</p>
                    {entry.scripture && <p style={styles.prayerScripture}>📖 {entry.scripture}</p>}
                    {entry.reflection && (
                      <div style={styles.reflectionBox}>
                        <em style={{ color: "#c4a469" }}>What is God teaching me:</em> {entry.reflection}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* SERVE TAB */}
        {tab === "serve" && (
          <div style={styles.fadeIn}>
            <div style={styles.toolbar}>
              <h2 style={styles.sectionTitle}>
                {role === "Pastor" ? "My Flock" : role === "Elder" ? "My Shepherding" : role === "Deacon" ? "Those I Serve" : "People On My Heart"}
              </h2>
              <button style={styles.addBtn} onClick={() => { setEditItem(null); setShowModal("person"); }}>
                <PlusIcon size={18} color="#1a1714" /> Add Person
              </button>
            </div>

            {/* Serve Sub-tabs */}
            <div style={styles.subTabBar}>
              {[
                { id: "list", label: "People" },
                { id: "overdue", label: `Need Contact (${overdueFlock.length})` },
                { id: "logs", label: "Care Log" },
              ].map(t => (
                <button key={t.id} style={{ ...styles.subTab, ...(subTab === t.id ? styles.subTabActive : {}) }} onClick={() => setSubTab(t.id)}>
                  {t.label}
                </button>
              ))}
            </div>

            {subTab === "list" && (
              <>
                <div style={{ ...styles.searchBox, marginBottom: 16 }}>
                  <SearchIcon size={16} color="#8a7d6b" />
                  <input style={styles.searchInput} placeholder="Search people..." value={searchText} onChange={e => setSearchText(e.target.value)} />
                </div>

                {filteredFlock.length === 0 ? (
                  <div style={styles.emptyState}>
                    <div style={styles.emptyIcon}>🤝</div>
                    <p style={styles.emptyText}>No one added yet.</p>
                    <p style={styles.emptySubtext}>Add the people God has placed on your heart to care for.</p>
                  </div>
                ) : (
                  <div style={styles.personList}>
                    {filteredFlock.sort((a, b) => daysAgo(b.lastContact) - daysAgo(a.lastContact)).map((person, i) => {
                      const overdue = daysAgo(person.lastContact) > reminderDays;
                      const daysSince = daysAgo(person.lastContact);
                      return (
                        <div key={person.id} style={{ ...styles.personCard, animationDelay: `${i * 0.04}s`, ...(overdue ? styles.personOverdue : {}) }}>
                          <div style={styles.personHeader}>
                            <div style={styles.personAvatar}>{person.name.charAt(0).toUpperCase()}</div>
                            <div style={{ flex: 1 }}>
                              <h3 style={styles.personName}>{person.name}</h3>
                              <div style={styles.personMetaRow}>
                                {person.tags && person.tags.map(tag => <span key={tag} style={styles.personTag}>{tag}</span>)}
                              </div>
                            </div>
                            <div style={styles.personDays}>
                              {overdue && <AlertIcon size={14} color="#c4785a" />}
                              <span style={{ color: overdue ? "#c4785a" : "#8a7d6b", fontSize: 13, fontWeight: overdue ? 600 : 400 }}>
                                {daysSince === Infinity ? "Never contacted" : daysSince === 0 ? "Today" : `${daysSince}d ago`}
                              </span>
                            </div>
                          </div>

                          {person.needs && person.needs.length > 0 && (
                            <div style={styles.needsRow}>
                              <span style={{ color: "#c4a469", fontSize: 12, fontWeight: 600 }}>NEEDS:</span>
                              {person.needs.map(n => <span key={n} style={styles.needTag}>{n}</span>)}
                            </div>
                          )}

                          {person.notes && <p style={styles.personNotes}>{person.notes}</p>}

                          <div style={styles.personActions}>
                            <button style={styles.logContactBtn} onClick={() => { setEditItem(person); setShowModal("logContact"); }}>
                              <PhoneIcon size={14} /> Log Contact
                            </button>
                            <button style={styles.iconBtn} onClick={() => { setEditItem(person); setShowModal("person"); }}><EditIcon size={14} color="#8a7d6b" /></button>
                            <button style={styles.iconBtn} onClick={() => {
                              if (confirm(`Remove ${person.name}?`)) {
                                updateFlock(prev => prev.filter(x => x.id !== person.id));
                                updateCareLogs(prev => prev.filter(x => x.personId !== person.id));
                              }
                            }}><TrashIcon size={14} color="#8a7d6b" /></button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </>
            )}

            {subTab === "overdue" && (
              overdueFlock.length === 0 ? (
                <div style={styles.emptyState}>
                  <div style={styles.emptyIcon}>✓</div>
                  <p style={styles.emptyText}>Everyone is cared for!</p>
                  <p style={styles.emptySubtext}>No one has gone more than {reminderDays} days without contact.</p>
                </div>
              ) : (
                <div style={styles.personList}>
                  {overdueFlock.sort((a, b) => daysAgo(b.lastContact) - daysAgo(a.lastContact)).map((person, i) => (
                    <div key={person.id} style={{ ...styles.personCard, ...styles.personOverdue, animationDelay: `${i * 0.04}s` }}>
                      <div style={styles.personHeader}>
                        <div style={{ ...styles.personAvatar, background: "#c4785a" }}>{person.name.charAt(0).toUpperCase()}</div>
                        <div style={{ flex: 1 }}>
                          <h3 style={styles.personName}>{person.name}</h3>
                          <span style={{ color: "#c4785a", fontSize: 13, fontWeight: 600 }}>
                            {daysAgo(person.lastContact) === Infinity ? "Never contacted" : `${daysAgo(person.lastContact)} days since last contact`}
                          </span>
                        </div>
                        <button style={styles.logContactBtn} onClick={() => { setEditItem(person); setShowModal("logContact"); }}>
                          <PhoneIcon size={14} /> Reach Out
                        </button>
                      </div>
                      {person.notes && <p style={styles.personNotes}>{person.notes}</p>}
                    </div>
                  ))}
                </div>
              )
            )}

            {subTab === "logs" && (
              careLogs.length === 0 ? (
                <div style={styles.emptyState}>
                  <div style={styles.emptyIcon}>📝</div>
                  <p style={styles.emptyText}>No care logs yet.</p>
                  <p style={styles.emptySubtext}>Log your contacts and visits to keep track of your care.</p>
                </div>
              ) : (
                <div style={styles.logList}>
                  {careLogs.sort((a, b) => new Date(b.date) - new Date(a.date)).map((log, i) => {
                    const person = flock.find(p => p.id === log.personId);
                    return (
                      <div key={log.id} style={{ ...styles.logCard, animationDelay: `${i * 0.04}s` }}>
                        <div style={styles.logHeader}>
                          <div style={styles.logAvatar}>{person ? person.name.charAt(0) : "?"}</div>
                          <div>
                            <span style={styles.logName}>{person ? person.name : "Unknown"}</span>
                            <span style={styles.logDate}>{formatDate(log.date)}</span>
                          </div>
                          <span style={styles.logType}>{log.type}</span>
                        </div>
                        <p style={styles.logNote}>{log.note}</p>
                        <button style={{ ...styles.iconBtn, position: "absolute", top: 12, right: 12 }} onClick={() => updateCareLogs(prev => prev.filter(x => x.id !== log.id))}>
                          <TrashIcon size={13} color="#8a7d6b" />
                        </button>
                      </div>
                    );
                  })}
                </div>
              )
            )}
          </div>
        )}
      </main>

      {/* MODALS */}
      {showModal && <div style={styles.overlay} onClick={() => setShowModal(null)} />}

      {/* Prayer Modal */}
      {showModal === "prayer" && (
        <PrayerModal
          item={editItem}
          onSave={(data) => {
            if (editItem) {
              updatePrayers(prev => prev.map(p => p.id === editItem.id ? { ...p, ...data } : p));
            } else {
              updatePrayers(prev => [{ id: generateId(), createdAt: todayStr(), answered: false, ...data }, ...prev]);
            }
            setShowModal(null);
          }}
          onClose={() => setShowModal(null)}
        />
      )}

      {/* Answer Prayer Modal */}
      {showModal === "answer" && editItem && (
        <AnswerModal
          prayer={editItem}
          onSave={(note) => {
            updatePrayers(prev => prev.map(p => p.id === editItem.id ? { ...p, answered: true, answeredAt: todayStr(), answerNote: note } : p));
            setShowModal(null);
          }}
          onClose={() => setShowModal(null)}
        />
      )}

      {/* Journal Modal */}
      {showModal === "journal" && (
        <JournalModal
          item={editItem}
          onSave={(data) => {
            if (editItem) {
              updateJournal(prev => prev.map(j => j.id === editItem.id ? { ...j, ...data } : j));
            } else {
              updateJournal(prev => [{ id: generateId(), date: todayStr(), ...data }, ...prev]);
            }
            setShowModal(null);
          }}
          onClose={() => setShowModal(null)}
        />
      )}

      {/* Person Modal */}
      {showModal === "person" && (
        <PersonModal
          item={editItem}
          role={role}
          onSave={(data) => {
            if (editItem) {
              updateFlock(prev => prev.map(p => p.id === editItem.id ? { ...p, ...data } : p));
            } else {
              updateFlock(prev => [{ id: generateId(), lastContact: null, ...data }, ...prev]);
            }
            setShowModal(null);
          }}
          onClose={() => setShowModal(null)}
        />
      )}

      {/* Log Contact Modal */}
      {showModal === "logContact" && editItem && (
        <LogContactModal
          person={editItem}
          onSave={(logData) => {
            updateCareLogs(prev => [{ id: generateId(), personId: editItem.id, date: todayStr(), ...logData }, ...prev]);
            updateFlock(prev => prev.map(p => p.id === editItem.id ? { ...p, lastContact: todayStr() } : p));
            setShowModal(null);
          }}
          onClose={() => setShowModal(null)}
        />
      )}
    </div>
  );
}

// --- MODALS ---

function PrayerModal({ item, onSave, onClose }) {
  const [title, setTitle] = useState(item?.title || "");
  const [details, setDetails] = useState(item?.details || "");
  const [category, setCategory] = useState(item?.category || "Personal");
  const [urgency, setUrgency] = useState(item?.urgency || "Ongoing");
  const [scripture, setScripture] = useState(item?.scripture || "");
  const [recurrence, setRecurrence] = useState(item?.recurrence || "None");

  return (
    <div style={styles.modal}>
      <div style={styles.modalHeader}>
        <h2 style={styles.modalTitle}>{item ? "Edit Prayer" : "New Prayer Request"}</h2>
        <button style={styles.iconBtn} onClick={onClose}><CloseIcon size={20} color="#8a7d6b" /></button>
      </div>
      <div style={styles.modalBody}>
        <label style={styles.label}>What would you like to pray for?</label>
        <input style={styles.input} value={title} onChange={e => setTitle(e.target.value)} placeholder="e.g., Healing for Mom's recovery" autoFocus />

        <label style={styles.label}>Details (optional)</label>
        <textarea style={styles.textarea} value={details} onChange={e => setDetails(e.target.value)} placeholder="Pour out your heart..." rows={3} />

        <div style={styles.formRow}>
          <div style={{ flex: 1 }}>
            <label style={styles.label}>Category</label>
            <select style={styles.select} value={category} onChange={e => setCategory(e.target.value)}>
              {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>
          <div style={{ flex: 1 }}>
            <label style={styles.label}>Urgency</label>
            <select style={styles.select} value={urgency} onChange={e => setUrgency(e.target.value)}>
              {URGENCY.map(u => <option key={u} value={u}>{u}</option>)}
            </select>
          </div>
        </div>

        <div style={styles.formRow}>
          <div style={{ flex: 1 }}>
            <label style={styles.label}>Recurring</label>
            <select style={styles.select} value={recurrence} onChange={e => setRecurrence(e.target.value)}>
              {RECURRENCE.map(r => <option key={r} value={r}>{r}</option>)}
            </select>
          </div>
        </div>

        <label style={styles.label}>Scripture to pray through (optional)</label>
        <input style={styles.input} value={scripture} onChange={e => setScripture(e.target.value)} placeholder="e.g., Philippians 4:6-7" />
      </div>
      <div style={styles.modalFooter}>
        <button style={styles.cancelBtn} onClick={onClose}>Cancel</button>
        <button style={styles.saveBtn} disabled={!title.trim()} onClick={() => onSave({ title, details, category, urgency, scripture, recurrence })}>
          {item ? "Update" : "Add Prayer"}
        </button>
      </div>
    </div>
  );
}

function AnswerModal({ prayer, onSave, onClose }) {
  const [note, setNote] = useState("");
  return (
    <div style={styles.modal}>
      <div style={styles.modalHeader}>
        <h2 style={styles.modalTitle}>🙌 Prayer Answered!</h2>
        <button style={styles.iconBtn} onClick={onClose}><CloseIcon size={20} color="#8a7d6b" /></button>
      </div>
      <div style={styles.modalBody}>
        <p style={{ color: "#a89880", marginBottom: 12, fontStyle: "italic" }}>"{prayer.title}"</p>
        <label style={styles.label}>How did God answer this prayer?</label>
        <textarea style={styles.textarea} value={note} onChange={e => setNote(e.target.value)} placeholder="Record God's faithfulness..." rows={4} autoFocus />
      </div>
      <div style={styles.modalFooter}>
        <button style={styles.cancelBtn} onClick={onClose}>Cancel</button>
        <button style={{ ...styles.saveBtn, background: "#7da87d" }} onClick={() => onSave(note)}>Mark as Answered</button>
      </div>
    </div>
  );
}

function JournalModal({ item, onSave, onClose }) {
  const [title, setTitle] = useState(item?.title || "");
  const [body, setBody] = useState(item?.body || "");
  const [scripture, setScripture] = useState(item?.scripture || "");
  const [reflection, setReflection] = useState(item?.reflection || "");

  return (
    <div style={styles.modal}>
      <div style={styles.modalHeader}>
        <h2 style={styles.modalTitle}>{item ? "Edit Entry" : "Journal Entry"}</h2>
        <button style={styles.iconBtn} onClick={onClose}><CloseIcon size={20} color="#8a7d6b" /></button>
      </div>
      <div style={styles.modalBody}>
        <label style={styles.label}>Title (optional)</label>
        <input style={styles.input} value={title} onChange={e => setTitle(e.target.value)} placeholder="A word for today..." autoFocus />
        <label style={styles.label}>What's on your heart?</label>
        <textarea style={styles.textarea} value={body} onChange={e => setBody(e.target.value)} placeholder="Write freely..." rows={5} />
        <label style={styles.label}>Scripture reference (optional)</label>
        <input style={styles.input} value={scripture} onChange={e => setScripture(e.target.value)} placeholder="e.g., Psalm 23" />
        <label style={styles.label}>What is God teaching me? (optional)</label>
        <textarea style={styles.textarea} value={reflection} onChange={e => setReflection(e.target.value)} placeholder="Reflect on His voice..." rows={3} />
      </div>
      <div style={styles.modalFooter}>
        <button style={styles.cancelBtn} onClick={onClose}>Cancel</button>
        <button style={styles.saveBtn} disabled={!body.trim()} onClick={() => onSave({ title, body, scripture, reflection })}>
          {item ? "Update" : "Save Entry"}
        </button>
      </div>
    </div>
  );
}

function PersonModal({ item, role, onSave, onClose }) {
  const [name, setName] = useState(item?.name || "");
  const [notes, setNotes] = useState(item?.notes || "");
  const [tags, setTags] = useState(item?.tags || []);
  const [needs, setNeeds] = useState(item?.needs || []);
  const [contactFreq, setContactFreq] = useState(item?.contactFreq || "Monthly");

  const toggleTag = (tag) => setTags(prev => prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag]);
  const toggleNeed = (need) => setNeeds(prev => prev.includes(need) ? prev.filter(n => n !== need) : [...prev, need]);

  return (
    <div style={styles.modal}>
      <div style={styles.modalHeader}>
        <h2 style={styles.modalTitle}>{item ? "Edit Person" : "Add Someone to Care For"}</h2>
        <button style={styles.iconBtn} onClick={onClose}><CloseIcon size={20} color="#8a7d6b" /></button>
      </div>
      <div style={styles.modalBody}>
        <label style={styles.label}>Name</label>
        <input style={styles.input} value={name} onChange={e => setName(e.target.value)} placeholder="Their name..." autoFocus />

        <label style={styles.label}>Notes about their situation</label>
        <textarea style={styles.textarea} value={notes} onChange={e => setNotes(e.target.value)} placeholder="What should you remember about them?" rows={3} />

        <label style={styles.label}>Desired contact frequency</label>
        <select style={styles.select} value={contactFreq} onChange={e => setContactFreq(e.target.value)}>
          {["Weekly", "Biweekly", "Monthly", "Quarterly"].map(f => <option key={f} value={f}>{f}</option>)}
        </select>

        <label style={styles.label}>Tags</label>
        <div style={styles.chipGrid}>
          {CARE_TAGS.map(tag => (
            <button key={tag} style={{ ...styles.chipBtn, ...(tags.includes(tag) ? styles.chipActive : {}) }} onClick={() => toggleTag(tag)}>
              {tag}
            </button>
          ))}
        </div>

        {(role === "Deacon" || role === "Elder" || role === "Pastor") && (
          <>
            <label style={styles.label}>Needs</label>
            <div style={styles.chipGrid}>
              {NEED_TYPES.map(need => (
                <button key={need} style={{ ...styles.chipBtn, ...(needs.includes(need) ? styles.chipActive : {}) }} onClick={() => toggleNeed(need)}>
                  {need}
                </button>
              ))}
            </div>
          </>
        )}
      </div>
      <div style={styles.modalFooter}>
        <button style={styles.cancelBtn} onClick={onClose}>Cancel</button>
        <button style={styles.saveBtn} disabled={!name.trim()} onClick={() => onSave({ name, notes, tags, needs, contactFreq })}>
          {item ? "Update" : "Add Person"}
        </button>
      </div>
    </div>
  );
}

function LogContactModal({ person, onSave, onClose }) {
  const [type, setType] = useState("Call");
  const [note, setNote] = useState("");

  return (
    <div style={styles.modal}>
      <div style={styles.modalHeader}>
        <h2 style={styles.modalTitle}>Log Contact — {person.name}</h2>
        <button style={styles.iconBtn} onClick={onClose}><CloseIcon size={20} color="#8a7d6b" /></button>
      </div>
      <div style={styles.modalBody}>
        <label style={styles.label}>Contact type</label>
        <div style={styles.chipGrid}>
          {["Call", "Text", "Visit", "Coffee", "Email", "Prayer Together"].map(t => (
            <button key={t} style={{ ...styles.chipBtn, ...(type === t ? styles.chipActive : {}) }} onClick={() => setType(t)}>{t}</button>
          ))}
        </div>
        <label style={styles.label}>Notes</label>
        <textarea style={styles.textarea} value={note} onChange={e => setNote(e.target.value)} placeholder={`How is ${person.name} doing? What did you talk about?`} rows={4} autoFocus />
      </div>
      <div style={styles.modalFooter}>
        <button style={styles.cancelBtn} onClick={onClose}>Cancel</button>
        <button style={styles.saveBtn} disabled={!note.trim()} onClick={() => onSave({ type, note })}>Log Contact</button>
      </div>
    </div>
  );
}

// --- STYLES ---
const styles = {
  app: {
    fontFamily: "'Source Sans 3', sans-serif",
    background: "linear-gradient(165deg, #1a1714 0%, #23201b 40%, #1e1b17 100%)",
    minHeight: "100vh",
    color: "#e8e0d4",
    position: "relative",
  },
  loadingScreen: {
    display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
    height: "100vh", background: "#1a1714", color: "#c4a469",
  },
  loadingCross: { fontSize: 48, marginBottom: 16, animation: "pulse 2s infinite" },
  loadingText: { fontFamily: "'Cormorant Garamond', serif", fontSize: 32, fontWeight: 700, letterSpacing: 2 },
  loadingSubtext: { fontSize: 14, color: "#8a7d6b", marginTop: 8 },

  header: {
    background: "linear-gradient(180deg, #211e19 0%, #1a1714 100%)",
    borderBottom: "1px solid #3d3529",
    position: "sticky", top: 0, zIndex: 100,
  },
  headerInner: {
    display: "flex", justifyContent: "space-between", alignItems: "center",
    padding: "16px 20px 8px",
  },
  logoArea: { display: "flex", alignItems: "center", gap: 12 },
  cross: { fontSize: 28, color: "#c4a469", fontWeight: 300 },
  title: {
    fontFamily: "'Cormorant Garamond', serif", fontSize: 24, fontWeight: 700,
    color: "#e8e0d4", letterSpacing: 1, lineHeight: 1.1,
  },
  subtitle: { fontSize: 12, color: "#8a7d6b", fontWeight: 300, letterSpacing: 2, textTransform: "uppercase" },
  settingsBtn: {
    background: "none", border: "1px solid #3d3529", borderRadius: 8,
    padding: 8, cursor: "pointer", display: "flex", alignItems: "center",
  },
  settingsPanel: {
    padding: "12px 20px", borderTop: "1px solid #2a2520", background: "#1e1b17",
  },
  settingRow: {
    display: "flex", alignItems: "center", justifyContent: "space-between",
    padding: "8px 0",
  },
  settingLabel: { fontSize: 14, color: "#a89880" },

  statsBar: {
    display: "flex", justifyContent: "center", alignItems: "center", gap: 0,
    padding: "10px 20px",
  },
  stat: { display: "flex", flexDirection: "column", alignItems: "center", padding: "0 16px" },
  statNum: { fontFamily: "'Cormorant Garamond', serif", fontSize: 22, fontWeight: 700, color: "#c4a469", lineHeight: 1.1 },
  statLabel: { fontSize: 10, color: "#8a7d6b", textTransform: "uppercase", letterSpacing: 1, marginTop: 2 },
  statDivider: { width: 1, height: 28, background: "#3d3529" },

  tabBar: {
    display: "flex", gap: 0, padding: "0 16px",
    borderTop: "1px solid #2a2520",
  },
  tab: {
    flex: 1, display: "flex", alignItems: "center", justifyContent: "center", gap: 4,
    padding: "12px 8px", border: "none", background: "none",
    color: "#8a7d6b", fontSize: 13, fontWeight: 500, cursor: "pointer",
    borderBottom: "2px solid transparent", transition: "all 0.2s",
    position: "relative",
  },
  tabActive: {
    color: "#c4a469", borderBottomColor: "#c4a469",
  },
  badge: {
    position: "absolute", top: 6, right: "20%",
    background: "#c4785a", color: "#fff", fontSize: 10, fontWeight: 700,
    width: 18, height: 18, borderRadius: "50%",
    display: "flex", alignItems: "center", justifyContent: "center",
  },

  main: { padding: "20px 16px 80px", maxWidth: 720, margin: "0 auto" },
  fadeIn: { animation: "fadeIn 0.3s ease" },

  toolbar: {
    display: "flex", justifyContent: "space-between", alignItems: "center",
    marginBottom: 16, gap: 12, flexWrap: "wrap",
  },
  sectionTitle: {
    fontFamily: "'Cormorant Garamond', serif", fontSize: 22, fontWeight: 600, color: "#e8e0d4",
  },
  searchBox: {
    display: "flex", alignItems: "center", gap: 8,
    background: "#23201b", border: "1px solid #3d3529", borderRadius: 10,
    padding: "8px 12px", flex: 1, minWidth: 160,
  },
  searchInput: {
    background: "none", border: "none", color: "#e8e0d4", fontSize: 14,
    outline: "none", width: "100%",
  },
  addBtn: {
    display: "flex", alignItems: "center", gap: 6,
    background: "#c4a469", color: "#1a1714", border: "none", borderRadius: 10,
    padding: "10px 16px", fontSize: 13, fontWeight: 600, cursor: "pointer",
    whiteSpace: "nowrap", transition: "all 0.2s",
  },

  filterRow: {
    display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 16,
  },
  filterChip: {
    padding: "6px 14px", borderRadius: 20, border: "1px solid #3d3529",
    background: "none", color: "#8a7d6b", fontSize: 12, cursor: "pointer",
    transition: "all 0.2s", fontWeight: 500,
  },
  filterActive: {
    background: "#c4a469", color: "#1a1714", borderColor: "#c4a469",
  },

  emptyState: {
    textAlign: "center", padding: "60px 20px",
  },
  emptyIcon: { fontSize: 48, marginBottom: 16, opacity: 0.6 },
  emptyText: { fontFamily: "'Cormorant Garamond', serif", fontSize: 20, color: "#a89880", marginBottom: 4 },
  emptySubtext: { fontSize: 14, color: "#6b5f52" },

  // Prayer cards
  prayerList: { display: "flex", flexDirection: "column", gap: 12 },
  prayerCard: {
    background: "#23201b", border: "1px solid #3d3529", borderRadius: 14,
    padding: 16, animation: "fadeIn 0.4s ease both", transition: "all 0.2s",
  },
  prayerPressing: { borderLeftColor: "#c4785a", borderLeftWidth: 3 },
  prayerAnswered: { borderLeftColor: "#7da87d", borderLeftWidth: 3, opacity: 0.85 },
  prayerHeader: { display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 },
  prayerMeta: { display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" },
  urgencyDot: { width: 8, height: 8, borderRadius: "50%", flexShrink: 0 },
  prayerCategory: { fontSize: 11, color: "#8a7d6b", textTransform: "uppercase", letterSpacing: 1, fontWeight: 600 },
  recurrenceBadge: { fontSize: 11, color: "#c4a469", background: "#2a2520", padding: "2px 8px", borderRadius: 10 },
  answeredBadge: { fontSize: 11, color: "#7da87d", background: "#1e2a1e", padding: "2px 8px", borderRadius: 10, fontWeight: 600 },
  prayerActions: { display: "flex", gap: 4 },
  prayerTitle: { fontFamily: "'Cormorant Garamond', serif", fontSize: 18, fontWeight: 600, color: "#e8e0d4", lineHeight: 1.3 },
  prayerDetails: { fontSize: 14, color: "#a89880", lineHeight: 1.5, marginTop: 6 },
  prayerScripture: { fontSize: 13, color: "#c4a469", marginTop: 8, fontStyle: "italic" },
  answerNote: {
    marginTop: 10, padding: 12, borderRadius: 10, background: "#1e2a1e",
    fontSize: 14, color: "#a8c4a8", lineHeight: 1.5,
  },
  prayerFooter: { display: "flex", gap: 16, marginTop: 10 },
  dateText: { fontSize: 12, color: "#6b5f52" },

  // Journal
  journalList: { display: "flex", flexDirection: "column", gap: 12 },
  journalCard: {
    background: "#23201b", border: "1px solid #3d3529", borderRadius: 14,
    padding: 16, animation: "fadeIn 0.4s ease both",
  },
  journalHeader: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 },
  journalDate: { fontFamily: "'Cormorant Garamond', serif", fontSize: 16, color: "#c4a469", fontWeight: 600 },
  journalTitle: { fontFamily: "'Cormorant Garamond', serif", fontSize: 18, color: "#e8e0d4", marginBottom: 8 },
  journalBody: { fontSize: 14, color: "#a89880", lineHeight: 1.6, whiteSpace: "pre-wrap" },
  reflectionBox: {
    marginTop: 12, padding: 12, borderRadius: 10, background: "#2a2520",
    fontSize: 13, color: "#c4a469", lineHeight: 1.5, fontStyle: "italic",
  },

  // Serve / People
  subTabBar: {
    display: "flex", gap: 4, marginBottom: 16,
    background: "#1e1b17", borderRadius: 10, padding: 4,
  },
  subTab: {
    flex: 1, padding: "8px 8px", borderRadius: 8, border: "none",
    background: "none", color: "#8a7d6b", fontSize: 12, cursor: "pointer",
    fontWeight: 500, transition: "all 0.2s", textAlign: "center",
  },
  subTabActive: { background: "#2a2520", color: "#c4a469" },

  personList: { display: "flex", flexDirection: "column", gap: 12 },
  personCard: {
    background: "#23201b", border: "1px solid #3d3529", borderRadius: 14,
    padding: 16, animation: "fadeIn 0.4s ease both",
  },
  personOverdue: { borderLeft: "3px solid #c4785a" },
  personHeader: { display: "flex", alignItems: "center", gap: 12, marginBottom: 8 },
  personAvatar: {
    width: 42, height: 42, borderRadius: "50%", background: "#c4a469",
    color: "#1a1714", display: "flex", alignItems: "center", justifyContent: "center",
    fontFamily: "'Cormorant Garamond', serif", fontSize: 20, fontWeight: 700, flexShrink: 0,
  },
  personName: { fontFamily: "'Cormorant Garamond', serif", fontSize: 18, fontWeight: 600, color: "#e8e0d4" },
  personMetaRow: { display: "flex", flexWrap: "wrap", gap: 4, marginTop: 2 },
  personTag: {
    fontSize: 10, color: "#c4a469", background: "#2a2520",
    padding: "2px 8px", borderRadius: 8, textTransform: "uppercase", letterSpacing: 0.5,
  },
  personDays: { display: "flex", alignItems: "center", gap: 4, flexShrink: 0 },
  needsRow: { display: "flex", alignItems: "center", flexWrap: "wrap", gap: 6, marginBottom: 8 },
  needTag: {
    fontSize: 11, color: "#e8e0d4", background: "#3d3529",
    padding: "3px 10px", borderRadius: 8,
  },
  personNotes: { fontSize: 13, color: "#8a7d6b", lineHeight: 1.5, marginBottom: 8 },
  personActions: { display: "flex", gap: 8, alignItems: "center" },
  logContactBtn: {
    display: "flex", alignItems: "center", gap: 6,
    background: "#2a2520", border: "1px solid #3d3529", borderRadius: 8,
    padding: "6px 12px", color: "#c4a469", fontSize: 12, fontWeight: 500,
    cursor: "pointer", transition: "all 0.2s",
  },

  // Care Logs
  logList: { display: "flex", flexDirection: "column", gap: 10 },
  logCard: {
    background: "#23201b", border: "1px solid #3d3529", borderRadius: 12,
    padding: 14, animation: "fadeIn 0.3s ease both", position: "relative",
  },
  logHeader: { display: "flex", alignItems: "center", gap: 10, marginBottom: 8 },
  logAvatar: {
    width: 32, height: 32, borderRadius: "50%", background: "#3d3529",
    color: "#c4a469", display: "flex", alignItems: "center", justifyContent: "center",
    fontFamily: "'Cormorant Garamond', serif", fontSize: 16, fontWeight: 600,
  },
  logName: { fontWeight: 600, color: "#e8e0d4", fontSize: 14, display: "block" },
  logDate: { fontSize: 12, color: "#6b5f52" },
  logType: {
    marginLeft: "auto", fontSize: 11, color: "#c4a469", background: "#2a2520",
    padding: "3px 10px", borderRadius: 8, fontWeight: 500,
  },
  logNote: { fontSize: 13, color: "#a89880", lineHeight: 1.5, paddingRight: 30 },

  // Modals
  overlay: {
    position: "fixed", inset: 0, background: "rgba(0,0,0,0.7)",
    zIndex: 200, backdropFilter: "blur(4px)",
  },
  modal: {
    position: "fixed", bottom: 0, left: 0, right: 0,
    background: "#23201b", borderTop: "1px solid #3d3529",
    borderRadius: "20px 20px 0 0", zIndex: 300,
    maxHeight: "85vh", overflow: "auto",
    animation: "slideUp 0.3s ease",
  },
  modalHeader: {
    display: "flex", justifyContent: "space-between", alignItems: "center",
    padding: "16px 20px 0",
  },
  modalTitle: {
    fontFamily: "'Cormorant Garamond', serif", fontSize: 22, fontWeight: 600, color: "#e8e0d4",
  },
  modalBody: { padding: "16px 20px" },
  modalFooter: {
    display: "flex", justifyContent: "flex-end", gap: 10,
    padding: "12px 20px 20px", borderTop: "1px solid #2a2520",
  },

  // Form elements
  label: { display: "block", fontSize: 12, color: "#8a7d6b", marginBottom: 6, marginTop: 14, textTransform: "uppercase", letterSpacing: 1, fontWeight: 600 },
  input: {
    width: "100%", padding: "10px 14px", background: "#1a1714", border: "1px solid #3d3529",
    borderRadius: 10, color: "#e8e0d4", fontSize: 14, outline: "none",
  },
  textarea: {
    width: "100%", padding: "10px 14px", background: "#1a1714", border: "1px solid #3d3529",
    borderRadius: 10, color: "#e8e0d4", fontSize: 14, outline: "none", resize: "vertical",
    lineHeight: 1.5, fontFamily: "'Source Sans 3', sans-serif",
  },
  select: {
    width: "100%", padding: "10px 14px", background: "#1a1714", border: "1px solid #3d3529",
    borderRadius: 10, color: "#e8e0d4", fontSize: 14, outline: "none",
  },
  formRow: { display: "flex", gap: 12 },

  chipGrid: { display: "flex", flexWrap: "wrap", gap: 6 },
  chipBtn: {
    padding: "6px 12px", borderRadius: 16, border: "1px solid #3d3529",
    background: "none", color: "#8a7d6b", fontSize: 12, cursor: "pointer",
    transition: "all 0.15s",
  },
  chipActive: { background: "#c4a469", color: "#1a1714", borderColor: "#c4a469", fontWeight: 600 },

  iconBtn: {
    background: "none", border: "none", cursor: "pointer", padding: 6,
    borderRadius: 6, display: "flex", alignItems: "center",
  },
  cancelBtn: {
    padding: "10px 20px", borderRadius: 10, border: "1px solid #3d3529",
    background: "none", color: "#8a7d6b", fontSize: 14, cursor: "pointer",
  },
  saveBtn: {
    padding: "10px 24px", borderRadius: 10, border: "none",
    background: "#c4a469", color: "#1a1714", fontSize: 14, fontWeight: 600,
    cursor: "pointer", transition: "all 0.2s",
  },
};
